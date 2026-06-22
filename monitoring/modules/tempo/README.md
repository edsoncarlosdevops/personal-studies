# Tempo — Guia de Domínio

> O que você precisa saber para configurar, otimizar e depurar o Tempo como um expert.

## Sumário

- [Arquitetura](#arquitetura)
- [Receivers](#receivers)
- [Storage](#storage)
- [Metrics Generator](#metrics-generator)
- [TraceQL Essencial](#traceql-essencial)
- [Integração Grafana](#integração-grafana)
- [Depuração](#depuração)
- [Performance](#performance)

---

## Arquitetura

### Componentes

```
Application → OTLP → Distributor → Ingester → Storage (S3/GCS)
                                ↓
                          Querier ← Compactor
                                ↓
                          Query Frontend ← Grafana
```

| Componente | Função |
|------------|--------|
| **Distributor** | Recebe traces, valida, divide em batches, replica |
| **Ingester** | Armazena em memória, faz flush para storage |
| **Querier** | Busca traces no storage + ingesters |
| **Query Frontend** | Cache, splitting, paralelização de queries |
| **Compactor** | Compacta blocks, aplica retenção, deduplica |

### Fluxo do Trace

```
1. App envia spans via OTLP → Distributor (porta 4317 gRPC / 4318 HTTP)
2. Distributor valida e envia para Ingester (hash por traceID)
3. Ingester mantém em memória + faz flush periódico para S3
4. Grafana consulta → Query Frontend → Querier → Storage
5. Compactor periodicamente compacta e aplica retenção
```

---

## Receivers

### Qual usar?

| Receiver | Protocolo | Porta | Quando usar |
|----------|-----------|-------|-------------|
| **OTLP gRPC** | OTLP via gRPC | 4317 | Aplicações com OpenTelemetry SDK |
| **OTLP HTTP** | OTLP via HTTP | 4318 | Aplicações sem suporte a gRPC |
| **Jaeger** | Jaeger Thrift/Proto | 14250 | Migração de Jaeger |
| **Zipkin** | Zipkin JSON/Thrift | 9411 | Migração de Zipkin |
| **Kafka** | Via tópico Kafka | - | Alta throughput, desacoplamento |

### Configuração Recomendada

```yaml
distributor:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317
        http:
          endpoint: 0.0.0.0:4318
    jaeger:
      protocols:
        grpc:
          endpoint: 0.0.0.0:14250
        thrift_http:
          endpoint: 0.0.0.0:14268
```

### OpenTelemetry Collector (Sidecar/Agent)

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024
  memory_limiter:
    check_interval: 1s
    limit_mib: 512

exporters:
  otlp:
    endpoint: tempo.monitoring.svc.cluster.local:4317
    tls:
      insecure: true

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlp]
```

---

## Storage

### Tempo NÃO tem Storage Próprio

O Tempo usa **object storage externo** (S3, GCS, Azure, MinIO). Ele nunca armazena dados localmente.

```yaml
storage:
  trace:
    backend: s3          # options: s3, gcs, azure, local
    s3:
      bucket: tempo-traces
      endpoint: s3.us-east-1.amazonaws.com
      access_key: ${AWS_ACCESS_KEY_ID}
      secret_key: ${AWS_SECRET_ACCESS_KEY}
    pool:
      max_workers: 400   # workers para upload/download
    wal:
      path: /var/tempo/wal
    block:
      bloom_filter_false_positive: 0.05
      index_downsample: 4
      encoding: zstd     # compressão (zstd > snappy > gzip)
```

### Estrutura de Dados

```
bucket/
├── tempo/
│   ├── blocks/
│   │   ├── <tenant>/
│   │   │   ├── <block_id>/
│   │   │   │   ├── data           # spans comprimidos
│   │   │   │   ├── index          # índice
│   │   │   │   └── bloomfilter    # bloom filter para busca rápida
│   │   │   └── ...
│   ├── compactor/
│   └── ...
```

### Retenção

```yaml
compactor:
  retention:
    dedupe: true                    # deduplica spans duplicados
  compaction:
    block_size_bytes: 1073741824    # 1GB por block
    flush_size_bytes: 52428800      # 50MB flush size
```

**No compactor você define a retenção:**

```yaml
overrides:
  defaults:
    metrics_generator:
      processors: [service_graphs, span_metrics]
    retention: 720h                 # 30 dias (via compactor)
```

---

## Metrics Generator

### O que faz?

Transforma **traces em métricas** (RED metrics) e envia para o Prometheus.

```yaml
metrics_generator:
  registry:
    external_labels:
      source: tempo
      cluster: monitoring
  storage:
    path: /var/tempo/generator/wal
    remote_write:
      - url: http://prometheus-server:80/api/v1/write
        send_exemplars: true
  processors:
    - service_graphs       # gera traces_service_graph_*
    - span_metrics         # gera traces_span_metrics_*
```

### O que você ganha

```promql
# Taxa de requests por serviço
rate(traces_service_graph_request_total[5m])

# Erro por serviço
rate(traces_service_graph_request_failed_total[5m]) / rate(traces_service_graph_request_total[5m])

# Latência p99 por serviço
histogram_quantile(0.99, rate(traces_span_metrics_latency_bucket[5m]))

# Duração média por endpoint
rate(traces_span_metrics_latency_sum[5m]) / rate(traces_span_metrics_latency_count[5m])
```

### Service Graphs

Requer **2 serviços que se comunicam via HTTP/gRPC** (ex: api-pedidos → api-pagamentos).

Gera:
- `traces_service_graph_request_total` — total de requests
- `traces_service_graph_request_failed_total` — requests com erro
- `traces_service_graph_request_duration_seconds` — duração

---

## TraceQL Essencial

TraceQL é a linguagem de consulta do Tempo (semelhante a LogQL).

```traceql
# Buscar spans com erro
{ .http.status_code >= 500 }

# Buscar por serviço
{ resource.service.name = "api-pedidos" }

# Duração maior que 1s
{ duration > 1s }

# Múltiplas condições
{ .http.method = "POST" && duration > 1s }

# Aninhado (span dentro de span)
{ resource.service.name = "api-pedidos" } >> { .http.status_code = 200 }

# Filtro por atributo do span
{ .http.route = "/api/pedidos" }

# Negação
{ .http.status_code != 200 }
```

### Na Prática (Grafana)

```
# Buscar traces lentos
{ duration > 2s }

# Buscar traces de um endpoint específico
{ .http.route = "/api/pedidos" }

# Buscar traces com erro
{ .http.status_code >= 500 }

# Buscar 20 traces mais lentos (no Grafana: ordenar por duration desc)
```

---

## Integração Grafana

### Configuração do Datasource

```yaml
datasources:
  datasources.yaml:
    datasources:
      - name: Tempo
        type: tempo
        url: http://tempo.monitoring.svc.cluster.local:3100
        jsonData:
          traces: true
          search:
            hide: false
          nodeGraph:
            enabled: true
          serviceMap:
            datasourceUid: ${PROMETHEUS_UID}
```

### Vinculando Logs → Traces

No painel de logs do Loki:

```json
{
  "derivedFields": [
    {
      "name": "trace_id",
      "matcherRegex": "trace_id=(\\w+)",
      "url": "$${__value.raw}",
      "datasourceUid": "TEMPO_UID"
    }
  ]
}
```

### Vinculando Métricas → Traces (Exemplars)

```promql
# No Prometheus, habilitar exemplars
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
```

Quando você clica em um ponto do gráfico, o Grafana abre o trace correspondente.

---

## Depuração

### Endpoints Úteis

| Endpoint | O que mostra |
|----------|--------------|
| `/api/traces/{traceID}` | Trace completo (raw JSON) |
| `/api/search` | Busca de traces |
| `/ready` | Health check |
| `/metrics` | Métricas do próprio Tempo |

### Métricas do Próprio Tempo

```promql
# Ingestão
rate(tempo_ingester_bytes_received_total[5m])
rate(tempo_ingester_spans_received_total[5m])

# Queries
histogram_quantile(0.99, rate(tempo_request_duration_seconds_bucket{route=~".*search.*"}[5m]))

# Erros
rate(tempo_request_duration_seconds_count{status_code=~"5.."}[5m])

# Blocks no storage
tempo_ingester_blocks_flushed_total

# Memória
process_resident_memory_bytes{job="tempo"}
```

### Problemas Comuns

| Sintoma | Causa | Solução |
|---------|-------|---------|
| Traces não aparecem | Aplicação não envia OTLP | Verificar OTEL SDK e endpoint |
| "trace not found" | Trace expirou ou não foi persistido | Verificar `max_bytes_per_trace` |
| Metrics Generator sem dados | `remote_write` não configurado | Verificar URL do Prometheus |
| Service Graphs vazios | Apenas 1 serviço | Não é possível sem 2+ serviços |
| Query lenta | Muitos spans sem filtro | Usar TraceQL com filtros |
| Ingester OOM | `max_bytes_per_trace` muito alto | Reduzir para 50MB |

### Comandos Úteis

```bash
# Verificar se Tempo está recebendo traces
curl -s http://localhost:3100/metrics | grep tempo_ingester_spans_received

# Buscar um trace específico
curl -s http://localhost:3100/api/traces/{traceID} | jq .

# Verificar configuração atual
curl -s http://localhost:3100/status | jq .
```

---

## Performance

### Boas Práticas

```yaml
# ❌ Enviar spans sem filtro — encarece storage e query

# ✅ Filtrar no SDK (sampling)
sampler:
  type: parentbased_traceidratio
  argument: 0.1  # 10% dos traces

# ❌ Spans muito grandes (payload enorme)
max_bytes_per_trace: 50_000_000  # 50MB — ajuste fino

# ✅ Batch no collector
processors:
  batch:
    timeout: 1s
    send_batch_size: 1024
```

### Recomendações de Recurso

| Tamanho | Spans/s | Distributor | Ingester | Querier | Storage |
|---------|---------|-------------|----------|---------|---------|
| Pequeno | < 100 | 1 CPU / 2GB | 2 CPU / 4GB | 1 CPU / 2GB | S3/OSS |
| Médio | 100-1000 | 2 CPU / 4GB | 4 CPU / 8GB | 2 CPU / 4GB | S3/OSS |
| Grande | 1000+ | 4 CPU / 8GB | 8 CPU / 16GB | 4 CPU / 8GB | S3/OSS + caching |

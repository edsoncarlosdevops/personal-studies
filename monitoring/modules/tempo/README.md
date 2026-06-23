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

---

## Desafios Práticos

### 🟢 Nível 1 — Iniciante

#### Desafio 1: Buscar traces de um serviço específico

**Contexto:** Você quer ver todos os traces do serviço `api-pedidos` para entender o fluxo de requisições.

**Ocorre quando:** Investigação de performance, entender dependências entre serviços, ou debug de um bug específico.

**TraceQL:**
```traceql
{ resource.service.name = "api-pedidos" }
```

**No Grafana:**
- Abra o **Explore** do Tempo
- Selecione **TraceQL** no modo de busca
- Cole a query acima
- Limite a 20 traces e ordenando por **Most recent**

**Entendendo:** `resource.service.name` é um atributo semântico do OpenTelemetry que identifica o serviço. Todo span tem esse atributo.

**Como depurar se não funcionar:**
```bash
# Verificar se o Tempo está recebendo traces
curl -s http://localhost:3100/metrics | grep tempo_ingester_spans_received

# Ver se o serviço está enviando spans
# (no pod da aplicação)
kubectl logs -n monitoring -l app=api-pedidos --tail=50 | grep "otel\|tempo\|trace"
```

---

#### Desafio 2: Encontrar traces lentos (>2s)

**Contexto:** Você quer identificar quais requisições estão lentas para priorizar otimizações.

**Ocorre quando:** Usuários reclamam de lentidão, ou você quer criar um SLO de latência.

**TraceQL:**
```traceql
{ duration > 2s }
```

**No Grafana:**
- Ordene por **Duration (descendente)** para ver os mais lentos primeiro
- Clique em um trace para ver a waterfall (qual span está consumindo mais tempo)

**Entendendo:** `duration` é o tempo total do trace (soma de todos os spans). >2s significa que a requisição completa levou mais de 2 segundos.

**Como depurar o trace lento:**
- Na waterfall, procure spans com duração alta (vermelho)
- Identifique se o gargalo é: banco, HTTP externo, processamento interno
- Ex: span `SELECT * FROM pedidos` levando 1.5s indica query lenta

---

#### Desafio 3: Buscar traces com erro HTTP

**Contexto:** Você quer ver traces que resultaram em erro HTTP 500 para investigar a causa.

**Ocorre quando:** Alerta de HTTP 5xx disparou, ou você está fazendo uma análise de resiliência.

**TraceQL:**
```traceql
{ .http.status_code >= 500 }
```

**Entendendo:** `.http.status_code` é um atributo do span de entrada HTTP. >=500 captura todos os erros de servidor (500, 502, 503, etc). O `.` indica atributo do span (não do resource).

**Variações úteis:**
```traceql
# Apenas 500
{ .http.status_code = 500 }

# Apenas 404
{ .http.status_code = 404 }

# Qualquer erro (4xx ou 5xx)
{ .http.status_code >= 400 }
```

---

### 🟡 Nível 2 — Intermediário

#### Desafio 4: Encontrar traces com erro em um endpoint específico

**Contexto:** Você quer ver traces com erro HTTP no endpoint `/api/pedidos` para monitorar a saúde desse fluxo específico.

**Ocorre quando:** Um deploy recente quebrou um endpoint específico, ou você está validando uma correção.

**TraceQL:**
```traceql
{ .http.route = "/api/pedidos" && .http.status_code >= 500 }
```

**Entendendo:** `&&` combina duas condições. Apenas spans que atendem a ambas (rota = "/api/pedidos" E status >= 500) são retornados.

**No Grafana:** Crie um botão no dashboard que abre essa busca pré-configurada no Explore.

**Como depurar se não funcionar:**
```bash
# Verificar se a aplicação envia atributos HTTP
# (no OTEL SDK da aplicação)
# Exemplo em Python:
from opentelemetry.semconv.trace import HttpFlavorValues
```

Se `.http.route` não estiver disponível, tente `.http.target` ou `.http.url`.

---

#### Desafio 5: Waterfall analysis — encontrar span mais lento

**Contexto:** Você abriu um trace lento e quer identificar qual span específico está consumindo mais tempo.

**Ocorre quando:** Análise de performance, otimização de endpoint.

**No Grafana (após abrir o trace):**
1. Veja a **Waterfall View** (barra horizontal de cada span)
2. Identifique o span mais largo (mais tempo)
3. Veja os atributos desse span (ex: `db.statement`, `http.url`, `http.method`)

**Exemplo de interpretação:**
| Span | Duração | Causa |
|------|---------|-------|
| `HTTP POST /api/pedidos` | 3.2s | Requisição total |
| `SELECT * FROM pedidos` | 2.8s | ⚠️ Query lenta (87% do tempo) |
| `HTTP POST /api/pagamentos` | 0.3s | Chamada externa rápida |
| `JSON serialization` | 0.1s | Processamento interno |

**Ação:** Nesse caso, a query SQL é o gargalo (2.8s de 3.2s). Adicione índice ou otimize a query.

---

#### Desafio 6: Ver traces entre 2 serviços (dependências)

**Contexto:** Você quer ver traces que passam por `api-pedidos` E `api-pagamentos` para entender a comunicação entre eles.

**Ocorre quando:** Investigação de latência em chamadas síncronas entre microsserviços.

**TraceQL:**
```traceql
{ resource.service.name = "api-pedidos" } >> { resource.service.name = "api-pagamentos" }
```

**Entendendo:** `>>` significa "ancestral de". Essa query retorna traces onde api-pedidos (ancestral) chamou api-pagamentos (descendente).

**No service graph (Grafana):**
- Vá em **Explore → Service Graph**
- Selecione os 2 serviços
- Veja: request rate, error rate, latency entre eles

**Como depurar se não funcionar:**
```bash
# Verificar se ambos os serviços estão instrumentados
curl -s 'http://localhost:9090/api/v1/query?query=traces_service_graph_request_total{client="api-pedidos"}' | jq '.data.result'

# Se vazio, um dos serviços não está enviando spans
```

---

### 🔴 Nível 3 — Avançado

#### Desafio 7: Metrics Generator — criar RED metrics para Prometheus

**Contexto:** Você quer taxas de erro, latência e throughput dos seus serviços sem instrumentar manualmente cada aplicação.

**Ocorre quando:** Stack de observabilidade com múltiplos serviços, onde instrumentar cada um é inviável.

**O que o Metrics Generator faz:**

```
Traces (Tempo) → Metrics Generator → Métricas (Prometheus)
```

**Métricas geradas automaticamente:**

```promql
# Rate (throughput)
rate(traces_service_graph_request_total{client="api-pedidos"}[5m])

# Errors
rate(traces_service_graph_request_failed_total{client="api-pedidos"}[5m])

# Latency (p99)
histogram_quantile(0.99, rate(traces_span_metrics_latency_bucket{service="api-pedidos"}[5m]))
```

**Configuração necessária no Tempo:**
```yaml
metrics_generator:
  processors: [service_graphs, span_metrics]
  registry:
    remote_write:
      - url: http://prometheus-server:80/api/v1/write
```

**Como depurar se não funcionar:**
```bash
# 1. Verificar se metrics_generator está ativo
curl -s http://localhost:3100/ready

# 2. Verificar se as métricas chegaram no Prometheus
curl -s 'http://localhost:9090/api/v1/query?query=traces_service_graph_request_total' | jq '.data.result | length'

# 3. Verificar remote_write
kubectl logs -n monitoring deployment/tempo | grep "remote_write\|generator"
```

---

#### Desafio 8: Correlacionar logs (Loki) com traces (Tempo)

**Contexto:** Você viu um erro no Loki e quer abrir o trace completo para entender o contexto.

**Ocorre quando:** Debugging de ponta a ponta — do log ao span.

**Configuração necessária (já feita):**

1. **Aplicação:** Deve incluir `trace_id` nos logs
2. **Loki:** Derived fields configurado para linkar ao Tempo
3. **Tempo:** Recebendo traces da mesma aplicação

**Fluxo:**
```
1. Veja o log no Grafana:
   {namespace="monitoring"} |= "error"

2. Clique no trace_id (link azul)

3. Abre o trace completo no Explore Tempo

4. Veja a waterfall com todos os spans
```

**Como garantir que trace_id está no log:**
```python
# Exemplo Python com OpenTelemetry + structlog
import structlog
from opentelemetry import trace

tracer = trace.get_tracer(__name__)
logger = structlog.get_logger()

with tracer.start_as_current_span("processar_pedido"):
    span = trace.get_current_span()
    trace_id = span.get_span_context().trace_id
    logger.info("processando pedido", trace_id=format(trace_id, '032x'))
```

---

#### Desafio 9: Sampling seletivo — preservar traces importantes

**Contexto:** O volume de traces é alto e você precisa armazenar apenas os mais importantes (erros e lentos) para economizar storage.

**Ocorre quando:** Alto throughput (>1000 spans/s), ou limite de custo com object storage.

**Estratégia: Head-based sampling (no OTEL Collector):**

```yaml
processors:
  probabilistic_sampler:
    sampling_percentage: 10  # 10% de todos os traces
  tail_sampling:
    policies:
      # Preservar TODOS os traces com erro
      - name: error-policy
        type: status_code
        status_code: ERROR
        sampling_percentage: 100
      # Preservar traces lentos (>2s)
      - name: slow-policy
        type: latency
        threshold_ms: 2000
        sampling_percentage: 100
      # Preservar traces de endpoints críticos
      - name: critical-endpoints
        type: string_attribute
        key: http.route
        values: [ "/api/pagamentos", "/api/pedidos/checkout" ]
        sampling_percentage: 100
```

**Entendendo:** `probabilistic_sampler` amostra 10% dos traces. `tail_sampling` garante que traces com erro, lentos ou de endpoints críticos sejam 100% preservados independente da amostragem.

**Cuidado:** `tail_sampling` precisa de mais memória porque avalia os spans depois de recebidos.

---

#### Desafio 10: Service Graph completo com alerta

**Contexto:** Você quer monitorar a comunicação entre todos os serviços e ser alertado quando uma dependência falha.

**Ocorre quando:** Arquitetura de microsserviços com dependências críticas.

**Pré-requisitos:**
- Tempo com Metrics Generator + Service Graphs
- Prometheus recebendo métricas do Tempo
- No mínimo 2 serviços se comunicando

**Service Graph no Grafana:**
```json
# Dashboard com visualização de service graph
{
  "title": "Service Graph",
  "type": "traces",
  "datasource": "Tempo",
  "query": {
    "query": "{ resource.service.name = \"api-pedidos\" } >> { resource.service.name = \"api-pagamentos\" }"
  }
}
```

**Métricas disponíveis:**
```promql
# Requests entre serviços
rate(traces_service_graph_request_total{client="api-pedidos", server="api-pagamentos"}[5m])

# Erros entre serviços
rate(traces_service_graph_request_failed_total{client="api-pedidos", server="api-pagamentos"}[5m])

# Latência entre serviços
histogram_quantile(0.99, rate(traces_service_graph_request_duration_seconds_bucket{client="api-pedidos", server="api-pagamentos"}[5m]))
```

**Alerta completo:**
```yaml
groups:
  - name: service_graph_alerts
    rules:
      - alert: ServiceHighErrorRate
        expr: |
          rate(traces_service_graph_request_failed_total{client="api-pedidos", server="api-pagamentos"}[5m])
          /
          rate(traces_service_graph_request_total{client="api-pedidos", server="api-pagamentos"}[5m]) * 100 > 5
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: 'api-pedidos → api-pagamentos com {{ $value | humanizePercentage }} de erro'
          description: 'A comunicação entre api-pedidos e api-pagamentos está com taxa de erro alta.'

      - alert: ServiceLatencyHigh
        expr: |
          histogram_quantile(0.99, rate(traces_service_graph_request_duration_seconds_bucket{client="api-pedidos", server="api-pagamentos"}[5m])) > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: 'Latência alta entre api-pedidos → api-pagamentos'
          description: 'P99 de latência > 1s na comunicação entre serviços.'
```

**Como depurar se não funcionar:**
```bash
# Verificar service graphs
curl -s 'http://localhost:9090/api/v1/query?query=traces_service_graph_request_total' | jq '.data.result | length'

# Se vazio, verificar a configuração do metrics_generator:
# 1. processors inclui service_graphs?
# 2. remote_write aponta para o Prometheus?
# 3. Há pelo menos 2 serviços com spans?
```

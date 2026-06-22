# Loki — Guia de Domínio

> O que você precisa saber para configurar, otimizar e depurar o Loki como um expert.

## Sumário

- [Coleta e Agentes](#coleta-e-agentes)
- [Pipeline Stages](#pipeline-stages)
- [Storage](#storage)
- [LogQL Essencial](#logql-essencial)
- [Depuração](#depuração)
- [Performance](#performance)

---

## Coleta e Agentes

### Qual agente usar?

| Agente | Quando usar |
|--------|-------------|
| **Promtail** | Apenas Loki, descoberta nativa Kubernetes, mais simples |
| **Fluent Bit** | Stack de logging multi-destino (Loki + Elastic + S3) |
| **Grafana Alloy** | Stack Grafana completa (Loki, Tempo, Prometheus), pipeline visual |

### Promtail — Configuração Essencial

```yaml
scrape_configs:
  - job_name: kubernetes-pods
    kubernetes_sd_configs:
      - role: pod
    pipeline_stages:
      - cri: {}                          # parse CRI log format
      - regex:
          expression: '^(?P<level>\w+)\s+(?P<message>.*)$'
      - labels:
          level:
      - timestamp:
          source: time
          format: RFC3339Nano
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        target_label: app
      - source_labels: [__meta_kubernetes_namespace]
        target_label: namespace
      - source_labels: [__meta_kubernetes_pod_name]
        target_label: pod
      - action: keep
        regex: true
        source_labels: [__meta_kubernetes_pod_annotation_grafana_com_loki_scrape]
```

### Fluent Bit — Configuração Essencial

```yaml
[INPUT]
    Name              tail
    Path              /var/log/containers/*.log
    multiline.parser  cri

[FILTER]
    Name                kubernetes
    Match               *
    Kube_Tag_Prefix     kube.*

[OUTPUT]
    Name                loki
    Match               *
    Host                loki.monitoring.svc.cluster.local
    Port                3100
    Labels              {job="fluentbit"}
    Auto_Kubernetes_Labels on
```

---

## Pipeline Stages

O pipeline do Promtail processa cada linha de log em stages:

```yaml
pipeline_stages:
  # 1. Parse — extrair dados estruturados
  - regex:
      expression: '^(?P<timestamp>\S+)\s+(?P<level>\S+)\s+(?P<message>.*)$'

  # 2. JSON — se o log for JSON
  - json:
      expressions:
        level: level
        message: msg
        trace_id: trace_id

  # 3. logfmt — se o log for key=value
  - logfmt:
      mapping:
        level: level
        msg: msg

  # 4. Timestamp — extrair timestamp do log (não usar o do Promtail)
  - timestamp:
      source: timestamp
      format: RFC3339Nano

  # 5. Labels — criar labels a partir do log
  - labels:
      level:
      app:

  # 6. Drop — descartar linhas que não interessam
  - drop:
      expression: 'healthcheck|heartbeat'

  # 7. Multiline — juntar stack traces
  - multiline:
      firstline: '^\d{4}-\d{2}-\d{2}'
      max_lines: 100
      max_wait_time: 3s

  # 8. Static Labels — adicionar labels fixas
  - static_labels:
      source: kubernetes
```

---

## Storage

### TSDB Index (Loki 2.8+)

A partir do Loki 2.8, o **TSDB index** substituiu o boltdb-shipper.

| Característica | boltdb-shipper | TSDB |
|---------------|----------------|------|
| Performance | ✅ Bom | 🔥 Excelente |
| Consumo de memória | Alto | Baixo |
| Query em dados antigos | Lento | Rápido |
| Compaction | Manual | Automática |

### Configuração Essencial

```yaml
ingester:
  chunk_idle_period: 30m        # tempo antes de flush
  chunk_retain_period: 1m       # manter na memória após flush
  max_chunk_age: 2h             # chunk máximo de idade
  max_transfer_retries: 0       # desabilitar transferência (Loki 3+)

querier:
  query_ingesters_within: 3h    # consultar ingesters para dados recentes

query_frontend:
  align_queries_with_step: true
  cache_results: true

compactor:
  retention_enabled: true       # habilitar retenção
  retention_rules:
    - selector:
        match: '{namespace="monitoring"}'
      period: 30d               # manter 30 dias
    - selector:
        match: '{namespace!~".*"}'
      period: 7d                # outros só 7 dias
```

### Limitações Conhecidas

- `max_look_back_period`: Loki NÃO consulta dados anteriores a esse período
- `reject_old_samples`: descarta amostras com timestamp muito antigo
- `creation_grace_period`: janela de tolerância para timestamp futuro

```yaml
limits_config:
  max_look_back_period: 72h       # só consegue ver 72h pra trás
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  creation_grace_period: 10m
```

---

## LogQL Essencial

### Filtros

```logql
# Básico — contém string
{namespace="monitoring"} |= "error"

# Regex
{namespace="monitoring"} |~ "err(or|o)"

# Negativo
{namespace="monitoring"} != "debug"

# Múltiplos labels
{namespace="monitoring", pod=~"api-.*"}
```

### Parse

```logql
# JSON automático
{namespace="monitoring"} | json

# logfmt (key=value)
{namespace="monitoring"} | logfmt

# Regex
{namespace="monitoring"} | regex "^(?P<ip>\\S+)\\s+(?P<method>\\S+)\\s+(?P<path>\\S+)"

# Pattern (mais rápido que regex)
{namespace="monitoring"} | pattern "<ip> - - <_> \"<method> <path> <_>\" <status> <size>"
```

### Métricas a partir de Logs

```logql
# Taxa de erro por namespace
rate({namespace="monitoring"} |= "error" [5m])

# Total de erros nas últimas 24h
sum(count_over_time({namespace="monitoring"} |= "error" [24h]))

# Top 5 containers com mais erros
topk(5, sum by (container) (rate({namespace="monitoring"} |= "error" [5m])))

# Percentual de erro
sum(rate({namespace="monitoring"} |= "error" [5m])) / sum(rate({namespace="monitoring"}[5m])) * 100
```

### Labels vs Linhas

```logql
# Retorna séries (para gráficos)
rate({namespace="monitoring"} |= "error" [5m])

# Retorna linhas (para tabela/logs panel)
{namespace="monitoring"} |= "error"
```

---

## Depuração

### Endpoints Úteis

| Endpoint | O que mostra |
|----------|--------------|
| `/loki/api/v1/label` | Labels disponíveis |
| `/loki/api/v1/label/{name}/values` | Valores de uma label |
| `/loki/api/v1/series` | Séries que correspondem a um filtro |
| `/ready` | Health check |
| `/metrics` | Métricas do próprio Loki |

### Métricas do Próprio Loki

```promql
# Ingestão
rate(loki_ingester_chunks_flushed_total[5m])
rate(loki_ingester_lines_received_total[5m])

# Queries
histogram_quantile(0.99, rate(loki_request_duration_seconds_bucket{route=~".*query.*"}[5m]))

# Erros
rate(loki_request_duration_seconds_count{status_code=~"5.."}[5m])

# Memória do ingester
loki_ingester_memory_chunks
process_resident_memory_bytes{job="loki"}
```

### Debug com logcli

```bash
# Instalar
docker run --rm grafana/logcli --help

# Consultar logs
logcli query '{namespace="monitoring"}' --tail

# Descobrir labels
logcli labels

# Valores de uma label
logcli labels namespace

# Série específica
logcli series '{namespace="monitoring"}'
```

### Problemas Comuns

| Sintoma | Causa | Solução |
|---------|-------|---------|
| "Data not found" | `max_look_back_period` muito curto | Aumentar para 72h+ |
| Ingester OOM | `chunk_idle_period` muito longo | Reduzir para 30m |
| Query lenta | Muitas labels de alta cardinalidade | Revisar pipeline stages |
| Logs não aparecem | Label `namespace` não configurada | Verificar relabel_configs |
| `max_entries_limit_per_query` | Limite de resultados | Aumentar ou paginar |

---

## Performance

### Boas Práticas

```yaml
# ❌ Evite labels de alta cardinalidade
labels:
  request_id:   # NUNCA — cada request vira uma série
  ip:           # NUNCA — cada IP vira uma série
  user_id:      # NUNCA — cada usuário vira uma série

# ✅ Prefira filtros no LogQL (mais barato)
{namespace="monitoring"} |= "error"
# Em vez de criar label "level=error"

# Use structured metadata (Loki 3+)
- structured_metadata:
    target_label: trace_id
```

### Recomendações de Recurso

| Tamanho | Logs/dia | Ingester | Querier | Storage |
|---------|----------|----------|---------|---------|
| Pequeno | < 100GB | 2 CPU / 4GB | 1 CPU / 2GB | S3/OSS |
| Médio | 100GB-1TB | 4 CPU / 8GB | 2 CPU / 4GB | S3/OSS |
| Grande | 1TB+ | 8 CPU / 16GB | 4 CPU / 8GB | S3/OSS + caching |

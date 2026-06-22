# Prometheus — Guia de Domínio

> O que você precisa saber para configurar, otimizar e depurar o Prometheus como um expert.

## Sumário

- [Coleta e Descoberta](#coleta-e-descoberta)
- [Storage e Performance](#storage-e-performance)
- [Alerting e Recording Rules](#alerting-e-recording-rules)
- [PromQL Essencial](#promql-essencial)
- [Depuração](#depuração)
- [Cardinalidade](#cardinalidade)

---

## Coleta e Descoberta

### ServiceMonitor vs PodMonitor vs Probe

| Tipo | Quando usar |
|------|-------------|
| **ServiceMonitor** | Serviço com `spec.selector` + porta nomeada (recomendado) |
| **PodMonitor** | Quando não há Service (ex: cAdvisor, node-exporter via DaemonSet) |
| **Probe** | Monitoramento externo (HTTP, TCP, ICMP) |

### relabel_configs — os 5 que você precisa saber

```yaml
relabel_configs:
  # 1. Dropar métricas que não interessam
  - source_labels: [__name__]
    regex: 'etcd_(.*)'
    action: drop

  # 2. Renomear label
  - source_labels: [__meta_kubernetes_pod_label_app]
    target_label: app
    action: replace

  # 3. Criar label a partir de metadados
  - source_labels: [__meta_kubernetes_namespace]
    target_label: namespace
    action: replace

  # 4. Manter apenas targets com label específica
  - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
    regex: 'true'
    action: keep

  # 5. Mapear porta correta
  - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
    regex: '([^:]+)(?::\d+)?;(\d+)'
    replacement: '$1:$2'
    target_label: __address__
    action: replace
```

### honor_labels

```yaml
# Quando o exportador já envia labels que você quer preservar
honor_labels: true   # não sobrescreve labels do target
honor_labels: false  # renomeia para exported_*
```

### scrape_interval e scrape_timeout

```yaml
# Configure por job, não global
scrape_configs:
  - job_name: 'cadvisor'
    scrape_interval: 15s   # padrão 60s é muito espaçado
    scrape_timeout: 10s    # sempre menor que scrape_interval
```

---

## Storage e Performance

### TSDB Internals

```
WAL (Write-Ahead Log) → Head (in-memory) → Blocks (on-disk)
```

- **WAL**: dados recentes (2h), seguro contra crash
- **Head**: dados em memória, consultas rápidas
- **Blocks**: compactados em disco, intervalos de 2h
- **Compaction**: junta blocks menores em maiores (reduz IO)

### Configuração Essencial

```yaml
storage:
  tsdb:
    retention:
      time: 30d        # quanto tempo manter
      size: 50GB       # limite de disco (opcional)
    wal_compression: true  # reduz IO de escrita
```

### Query Optimization

```promql
# ❌ Ruim — varre tudo
rate(container_cpu_usage_seconds_total[5m])

# ✅ Bom — filtra antes
rate(container_cpu_usage_seconds_total{namespace="monitoring"}[5m])

# ❌ Ruim — cardinalidade explode
count({__name__=~".*"}) by (instance, job, namespace, pod, container)

# ✅ Bom — específico
count(kube_pod_info) by (namespace)
```

### Quando usar rate vs increase

| Função | Retorna | Uso |
|--------|---------|-----|
| `rate(metric[5m])` | Taxa por segundo | CPU, requests/s, throughput |
| `increase(metric[5m])` | Valor total no período | Restarts, errors absolutos |
| `irate(metric[5m])` | Taxa instantânea | Picos rápidos (últimos 2 pontos) |

---

## Alerting e Recording Rules

### Estrutura de Regras

```yaml
groups:
  - name: observabilidade
    interval: 30s  # avalia a cada 30s (padrão 60s)
    rules:
      - record: namespace:cpu_usage:rate5m
        expr: |
          sum(rate(container_cpu_usage_seconds_total{namespace!=""}[5m])) by (namespace)

      - alert: HighCPUUsage
        expr: |
          namespace:cpu_usage:rate5m > 0.8
        for: 10m          # só dispara se sustentar por 10 min
        labels:
          severity: warning
        annotations:
          summary: '{{ $labels.namespace }} com CPU alta ({{ $value | humanizePercentage }})'
```

### Evitando Falso Positivo

```promql
# ❌ Dispara em pico de 1 minuto
rate(metric[1m]) > 0.9

# ✅ Só dispara se médio sustentado
avg_over_time(rate(metric[5m])[15m:1m]) > 0.9
```

---

## PromQL Essencial

### 4 Funções que Você TEM que Saber

```promql
rate(metric[5m])                           # taxa por segundo
increase(metric[5m])                       # valor total no período
avg_over_time(metric[5m])                  # média móvel
quantile_over_time(0.99, metric[5m])       # latência p99
```

### Join (Operação Binária)

```promql
# Multiplicar CPU usage pelo custo do node
rate(container_cpu_usage_seconds_total[5m]) * on(instance) group_left() node_cpu_hourly_cost

# Dividir uso por request
container_memory_working_set_bytes / on(container, pod) group_left() kube_pod_container_resource_requests{resource="memory"}
```

### Top k

```promql
# Top 5 namespaces por CPU
topk(5, sum(rate(container_cpu_usage_seconds_total{namespace!=""}[5m])) by (namespace))

# Bottom 5 (menos uso)
bottomk(5, sum(rate(container_cpu_usage_seconds_total{namespace!=""}[5m])) by (namespace))
```

---

## Depuração

### Endpoints Úteis

| Endpoint | O que mostra |
|----------|--------------|
| `/api/v1/status/tsdb` | Estatísticas do TSDB, séries por label |
| `/api/v1/targets` | Health, scrape duration, último erro |
| `/api/v1/rules` | Regras de alerta e recording |
| `/api/v1/alerts` | Alertas ativos |
| `/metrics` | Métricas do próprio Prometheus |

### Métricas do Próprio Prometheus

```promql
# Cardinalidade — quantas séries existem
prometheus_tsdb_head_series

# Scrapes com erro
rate(prometheus_target_scrapes_exceeded_sample_limit_total[5m])

# Queries lentas (>1s)
histogram_quantile(0.99, rate(prometheus_engine_query_duration_seconds_bucket[5m]))

# WAL replay time (no startup)
prometheus_tsdb_wal_replay_duration_seconds

# Uso de disco
prometheus_tsdb_storage_blocks_bytes
```

### Debug de Scrape

```bash
# Verificar se um target está sendo scapeado
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health=="down")'

# Ver amostras de uma métrica
curl -s 'http://localhost:9090/api/v1/query?query=up{job="prometheus"}'

# Valores disponíveis para uma label
curl -s 'http://localhost:9090/api/v1/label/namespace/values'
```

---

## Cardinalidade

### O Maior Problema do Prometheus

**Sintoma**: Prometheus lento, OOM, queries demoram, disco enche rápido.

**Diagnóstico**:

```promql
# Quantas séries no total
prometheus_tsdb_head_series

# Séries por job (top 5)
topk(5, count by (job) ({__name__=~".+"}))

# Labels que mais explodem
count by (__name__) ({__name__=~"container_(.*)"})
```

**Causas Comuns**:

| Causa | Exemplo | Solução |
|-------|---------|---------|
| Label com valor único por pod | `pod_ip`, `instance_id` | `metric_relabel_configs` para dropar |
| Request/path como label | `path="/api/users/123"` | Dropar ou sanitizar |
| Timestamp no label | `date="2026-06-22T14:00:00Z"` | Dropar — use tempo da série |
| Container efêmero | Jobs que criam pods únicos | Usar `__meta_kubernetes_pod_controller_kind=JobMonitor` |

**Prevenção**:

```yaml
metric_relabel_configs:
  - source_labels: [pod_ip]
    action: drop
  - source_labels: [container_id]
    action: drop
  - source_labels: [__name__]
    regex: 'etcd_(.*)'
    action: drop
```

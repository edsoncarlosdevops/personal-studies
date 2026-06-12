# Prometheus

## Visao Geral

Prometheus coleta metricas de alvos configurados em intervalos regulares, avalia regras de alerta e exibe resultados.

## O que ele faz no projeto

O Prometheus e o backbone de metricas do cluster. Ele:

1. **Coleta metricas** do OTEL Collector (porta 8889)
2. **Coleta metricas** dele mesmo (localhost:9090)
3. **Armazena** (sem persistencia em lab)
4. **Expoe** dados para o Grafana via datasource

## Arquitetura do Scraping

```
App (OTel SDK) ---> OTEL Collector (:4317)
                              |
                    +---------+---------+
                    |                   |
              :8889 (export)     :4317 (Tempo)
                    |                   |
              Prometheus           Tempo
                    |                   |
              Grafana (query)     Grafana (query)
```

## [ATENCAO] Scrape Configs

O Prometheus so raspa targets listados em `extraScrapeConfigs`.
Sem o target do OTEL Collector, metricas como `http_requests_total`
nunca aparecem nas queries.

```yaml
extraScrapeConfigs: |
  - job_name: opentelemetry-collector
    scrape_interval: 15s
    static_configs:
      - targets:
        - opentelemetry-collector.monitoring.svc.cluster.local:8889
```

## Queries  Uteis (PromQL)

### Saude do Cluster

```promql
# Quais targets estao respondendo
up

# % de targets UP
(count(up == 1) / count(up)) * 100
```

### Metricas do OTEL Collector

```promql
# Spans recebidos por segundo (taxa)
rate(otelcol_receiver_accepted_spans[1m])

# Spans com erro
rate(otelcol_receiver_refused_spans[1m])

# Memoria do Collector
otelcol_process_memory_rss
```

### Metricas Customizadas (via SDK OTel)

```promql
# Total de requisicoes HTTP
http_requests_total

# Requisicoes por rota
sum by(route) (http_requests_total)

# Requisicoes por metodo
sum by(method) (http_requests_total)

# Total de requisicoes (contador acumulado)
sum(http_requests_total)

# Requisicoes por segundo
rate(http_requests_total[1m])

# Requisicoes por segundo por rota
sum by(route) (rate(http_requests_total[1m]))

# Top 5 rotas mais chamadas
topk(5, sum by(route) (rate(http_requests_total[5m])))
```

### Latencia (Histogramas)

```promql
# Latencia media por rota (ms)
sum by(route) (rate(http_request_duration_ms_sum[5m]))
/
sum by(route) (rate(http_request_duration_ms_count[5m]))

# Latencia media geral (ms)
sum(rate(http_request_duration_ms_sum[5m]))
/
sum(rate(http_request_duration_ms_count[5m]))

# Percentil 95 (aproximado)
histogram_quantile(0.95,
  sum by(route, le) (rate(http_request_duration_ms_bucket[5m]))
)
```

### Taxa de Erro

```promql
# % de erro por rota
sum by(route) (rate(http_requests_total{status=~"5..|4.."}[5m]))
/
sum by(route) (rate(http_requests_total[5m]))
* 100

# Requisicoes com erro (400, 500)
http_requests_total{status=~"4..|5.."}
```

### Usuarios Online

```promql
# Usuarios online atualmente
users_online

# Usuarios por tier
sum by(tier) (users_online)

# Total de usuarios
sum(users_online)
```

## Como acessar

```bash
# Port-forward para a UI do Prometheus
kubectl -n monitoring port-forward svc/prometheus-server 9090:80

# Acessar http://localhost:9090
```

## Comandos Uteis

```bash
# Ver status do Prometheus
kubectl get pods -n monitoring | grep prometheus

# Ver targets configurados
curl http://localhost:9090/api/v1/targets

# Ver configuracao atual
curl http://localhost:9090/api/v1/status/config

# Query via API
curl "http://localhost:9090/api/v1/query?query=up"

# Query com range (ultimos 5 min)
curl "http://localhost:9090/api/v1/query_range?query=up&start=$(date -v-5M +%s)&end=$(date +%s)&step=15s"
```

## Referencias

- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Histograms](https://prometheus.io/docs/concepts/metric_types/#histogram)
- [Rate vs Increase](https://prometheus.io/docs/prometheus/latest/querying/functions/#rate)

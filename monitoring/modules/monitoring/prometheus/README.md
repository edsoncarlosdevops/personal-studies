# Prometheus

## Visao Geral

Prometheus e um sistema de monitoramento e alerta open-source, projetado para confiabilidade e simplicidade. Ele coleta metricas de alvos configurados em intervalos regulares, avalia regras de alerta e exibe resultados.

## O que ele faz no projeto

O Prometheus e o backbone de metricas do cluster. Ele:

1. **Coleta metricas** do OTEL Collector (porta 8889)
2. **Coleta metricas** dele mesmo (localhost:9090)
3. **Armazena** com retencao de 5 dias (sem persistencia em lab)
4. **Expoe** dados para o Grafana via datasource

## Arquitetura do Scraping

```
OTEL Collector (:8889) ----+
                           |
Prometheus Server (:9090) -+----> [Storage TSDB]
                           |
kube-state-metrics (desligado)
                           |
node-exporter (desligado)
```

No lab, os componentes extras estao desligados para economizar recursos do t3.medium.

## Configuracoes Importantes

### O que foi desabilitado (e por que)

| Componente | Status | Motivo |
|-----------|--------|--------|
| Alertmanager | disabled | Usamos o modulo separado |
| Pushgateway | disabled | Nao necessario em lab |
| node-exporter | disabled | Economizar recursos do t3.medium |
| kube-state-metrics | disabled | Economizar recursos do t3.medium |

### Por que persistencia desabilitada?

```yaml
persistentVolume:
  enabled: false
```

No EKS com t3.medium (2 vCPU, 4GB RAM), habilitar persistencia:
- Cria um PVC de 8GB no EBS gp2
- gp2 tem `volumeBindingMode: WaitForFirstConsumer`
- Atrasa o scheduling do pod
- Para lab, nao vale a complexidade

### Retencao de dados

```yaml
retention: "5d"
```

Apenas 5 dias de metricas. Em producao, aumente para 15-30 dias com persistencia habilitada e um volume EBS maior.

## Metricas Disponiveis

### Do Prometheus (ele mesmo)
- `prometheus_target_interval_length_seconds`
- `prometheus_tsdb_head_series`
- `prometheus_engine_query_duration_seconds`

### Do OTEL Collector (via scraping :8889)
- `otelcol_process_memory_rss`
- `otelcol_process_cpu_seconds`
- `otelcol_exporter_sent_spans`

### Da sua aplicacao (via SDK OTel)
- `http.server.duration` (latencia das requisicoes)
- `http.server.request_count` (numero de requisicoes)
- `db.client.connections_usage` (conexoes com o banco)

## Como acessar

```bash
# Port-forward para acessar a UI do Prometheus
kubectl -n monitoring port-forward svc/prometheus-server 9090:80

# Abrir no navegador
# http://localhost:9090

# Exemplos de queries para testar:
# - up
# - prometheus_target_interval_length_seconds
# - rate(prometheus_tsdb_head_series[5m])
```

## Comandos Uteis

```bash
# Ver status do Prometheus
kubectl get pods -n monitoring | grep prometheus

# Ver targets configurados
kubectl -n monitoring port-forward svc/prometheus-server 9090:80
# http://localhost:9090/targets

# Ver configuracoes carregadas
# http://localhost:9090/config

# Query rapida via API
curl "http://localhost:9090/api/v1/query?query=up"
```

## Referencias

- [Documentacao Oficial](https://prometheus.io/docs/introduction/overview/)
- [Data Model](https://prometheus.io/docs/concepts/data_model/)
- [Querying (PromQL)](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Helm Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus)

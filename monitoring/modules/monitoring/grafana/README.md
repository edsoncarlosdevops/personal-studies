# Grafana

## Visao Geral

Grafana e a plataforma de observabilidade que unifica metricas, logs e traces em dashboards interativos. Ele se conecta a diversas fontes de dados (datasources) e permite criar visualizacoes, alertas e exploracao ad-hoc.

## O que ele faz no projeto

O Grafana e o front-end unico de observabilidade. Ele ja vem pre-configurado com 3 datasources:

```
Grafana (porta 3000)
     |
     +-- Prometheus -> http://prometheus-server:80 (metricas)
     |
     +-- Loki       -> http://loki:3100         (logs)
     |
     +-- Tempo      -> http://tempo:3200        (traces)
```

## Datasources Configurados

### Prometheus (metricas)

```yaml
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus-server:80
    isDefault: true
    jsonData:
      httpMethod: POST
```

- **isDefault: true** - todas as queries usam esse por padrao
- **httpMethod: POST** - mais performatico para queries grandes

### Loki (logs)

```yaml
  - name: Loki
    type: loki
    url: http://loki:3100
    jsonData:
      timeout: 60
      maxLines: 1000
```

- **timeout: 60** - timeout de 60s para queries de log
- **maxLines: 1000** - maximo de linhas retornadas por query

### Tempo (traces)

```yaml
  - name: Tempo
    type: tempo
    url: http://tempo:3200
    jsonData:
      traces: true
```

- **traces: true** - habilita a busca de traces no Explore

## Como acessar

```bash
# Port-forward
kubectl -n monitoring port-forward svc/grafana 3000:80

# Acessar
# http://localhost:3000
```

### Credenciais

- **user**: admin
- **password**:
```bash
kubectl get secret -n monitoring grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d
```

## O que explorar

### Explore - Metricas (Prometheus)
```
/queries/prometheus
- up
- rate(http.server.duration_sum[5m])
- avg:rate(db.client.connections_usage[5m])
```

### Explore - Logs (Loki)
```
/queries/loki
{app="app-rds"} |= "error"
{namespace="app-dev"} |= "POST /api/users"
```

### Explore - Traces (Tempo)
```
Service Name: app-rds-dev
Operation: GET /
Min Duration: 1ms
```

## Comandos Uteis

```bash
# Ver logs do Grafana
kubectl logs -n monitoring deployment/grafana

# Recarregar datasources sem reiniciar
kubectl rollout restart -n monitoring deployment/grafana

# Ver configuracoes do Grafana via API
kubectl -n monitoring port-forward svc/grafana 3000:80
curl -u admin:$(kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 -d) http://localhost:3000/api/datasources
```

## Dicas

### Para criar um dashboard rapido:

1. Acesse o Grafana
2. Dashboards > New Dashboard > Add visualization
3. Selecione Prometheus como datasource
4. Query: `rate(http.server.duration_sum[5m])`
5. Salve o dashboard

### Para importar dashboards prontos:

1. Dashboards > New > Import
2. Cole o ID do dashboard no [grafana.com/dashboards](https://grafana.com/dashboards)
3. Exemplos uteis:
   - **Node.js**: 11159 (Node.js Application)
   - **Kubernetes**: 315 (Kubernetes Cluster)
   - **PostgreSQL**: 9628 (PostgreSQL Database)

## Referencias

- [Documentacao Oficial](https://grafana.com/docs/grafana/latest/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [LogQL (Loki)](https://grafana.com/docs/loki/latest/logql/)

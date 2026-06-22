# Grafana Loki

## Visao Geral

Loki e um sistema de agregacao de logs inspirado no Prometheus. Diferente do Elasticsearch, ele indexa apenas metadados (labels) em vez do texto completo, tornando o armazenamento extremamente barato e performatico.

## O que ele faz no projeto

Loki coleta e armazena logs de todas as aplicacoes do cluster EKS, permitindo busca e correlacao com metricas (Prometheus) e traces (Tempo).

## Como Loki e Diferente

| Aspecto | Loki | Elasticsearch |
|---------|------|---------------|
| Indexacao | So labels (como Prometheus) | Texto completo |
| Custo | Baixo (1/10 do ES) | Alto |
| Velocidade de busca | Rapida para labels | Rapida para full-text |
| Integracao | Nativa com Grafana | Plugins |
| Complexidade | Simples (SingleBinary) | Complexa (multiplos componentes) |

## Arquitetura Atual (SingleBinary)

No lab, Loki roda em modo SingleBinary - todos os componentes em um processo so:

```
[Apps] -> stdout -> [Promtail/DaemonSet] -> :3100 -> [Loki SingleBinary]
                                                          |
                                                    Armazenamento
                                                    (filesystem)
```

### Modos de Deploy

| Modo | Descricao | Quando usar |
|------|-----------|-------------|
| SingleBinary | Tudo em um pod | Lab, baixo volume |
| SimpleScalable | Read/Write separados | Medio volume |
| Distributed | Cada componente isolado | Alto volume, producao |

## Configuracoes Importantes

### Path Prefix (/tmp/loki)

```yaml
loki:
  commonConfig:
    path_prefix: /tmp/loki
```

O container do Loki roda como user nao-root (UID 10001). O diretorio `/var/loki` e read-only para esse user, entao usamos `/tmp/loki` que tem permissao de escrita.

### Storage (filesystem)

```yaml
storage:
  type: "filesystem"
  filesystem:
    chunks_directory: /tmp/loki/chunks
    rules_directory: /tmp/loki/rules
```

No lab, usamos armazenamento local (emptyDir). Ao reiniciar o pod, os logs sao perdidos.

### Schema (TSDB)

```yaml
schemaConfig:
  configs:
    - from: "2024-01-01"
      store: tsdb
      schema: v13
```

TSDB (Time Series Database) e o formato de indice mais moderno do Loki, similar ao Prometheus.

## Produção: S3 + SimpleScalable

Em producao, a configuracao ideal seria:

```yaml
deploymentMode: SimpleScalable

loki:
  storage:
    type: "s3"
    s3:
      s3: s3://us-east-1/meu-bucket-logs
      s3forcepathstyle: true
  limits_config:
    retention_period: 30d
```

## Query Language (LogQL)

LogQL e a linguagem de consulta do Loki. Exemplos:

```logql
# Buscar logs de uma app especifica
{app="app-rds"}

# Logs de erro
{namespace="app-dev"} |= "error"

# Logs com JSON parseado
{app="app-rds"} | json | status >= 400

# Logs nos ultimos 15 minutos
{app="app-rds"} |= "error" != "timeout"
```

## Comandos Uteis

```bash
# Ver status do Loki
kubectl get pods -n monitoring | grep loki

# Port-forward para API do Loki
kubectl port-forward -n monitoring svc/loki 3100:3100

# Testar query de logs
curl "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={app="app-rds"}' \
  --data-urlencode 'limit=10'

# Ver metricas do Loki
kubectl port-forward -n monitoring svc/loki 3100:3100
curl http://localhost:3100/metrics

# Ver readiness do Loki
curl http://localhost:3100/ready
```

## Referencias

- [Documentacao Oficial](https://grafana.com/docs/loki/latest/)
- [LogQL](https://grafana.com/docs/loki/latest/logql/)
- [Modos de Deploy](https://grafana.com/docs/loki/latest/setup/install/helm/deployment-modes/)
- [Armazenamento S3](https://grafana.com/docs/loki/latest/storage/)

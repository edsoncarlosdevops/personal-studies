# Modulo Terraform: app-rds

Deploy de uma aplicacao Node.js CRUD no EKS que conecta no RDS PostgreSQL
e envia telemetria para o OpenTelemetry Collector.

## Variaveis

| Variavel | Descricao | Default |
|----------|-----------|---------|
| environment | Nome do ambiente | - |
| db_endpoint | Endpoint do RDS | - |
| db_port | Porta do RDS | 5432 |
| db_name | Nome do banco | - |
| db_username | Usuario do banco | - |
| db_password | Senha do banco (sensitive) | - |
| app_image | Imagem Docker da aplicacao | edsoncarlosdevops/app-rds:latest |
| app_replicas | Numero de replicas | 1 |
| otel_collector_endpoint | Endpoint do OTEL Collector | opentelemetry-collector.monitoring.svc.cluster.local:4317 |

## Fluxo de deploy

```bash
# 1. Build da imagem
cd deploy/apps/app-rds/src
docker build -t edsoncarlosdevops/app-rds:latest .
docker push edsoncarlosdevops/app-rds:latest

# 2. Deploy via Terragrunt
cd deploy/apps/app-rds
terragrunt apply
```

## Observabilidade

A aplicacao envia:
- Traces -> OTEL Collector -> Tempo
- Metricas -> OTEL Collector -> Prometheus

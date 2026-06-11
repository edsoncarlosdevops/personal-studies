# Grafana Tempo

## Visao Geral

Tempo e um backend de tracing distribuido de alta escala e baixo custo. Ele foi projetado para indexar traces usando apenas armazenamento de objetos (S3/GCS), sem precisar de um banco de indices separado.

## O que ele faz no projeto

Tempo recebe traces do OTEL Collector, armazena e permite consulta via Grafana. Cada trace representa o caminho completo de uma requisicao atraves dos servicos.

## Conceitos de Tracing

### Span

A unidade basica do tracing. Cada operacao (chamada HTTP, query SQL) e um span:

```
[Span: GET /api/users] (duracao: 150ms)
  +-- [Span: query SELECT * FROM users] (duracao: 45ms)
  +-- [Span: render template index.ejs] (duracao: 20ms)
```

### Trace

O conjunto completo de spans que representa uma requisicao:

```
[Trace: GET /] (duracao total: 200ms)
  +-- [Span: Express middleware] - 5ms
  +-- [Span: pool.query] - 50ms
  +-- [Span: res.render] - 30ms
  +-- [Span: resposta HTTP] - 15ms
```

### Context Propagation

O tracing funciona porque o contexto (traceId, spanId) e propagado entre servicos via headers HTTP:

```
Headers injetados pelo SDK OTel:
- traceparent: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01
- tracestate: ...
- baggage: ...
```

## Como Funciona no Projeto

```
App RDS (Node.js + SDK OTel)
       |
       | OTLP gRPC (:4317)
       v
OTEL Collector
       |
       | OTLP gRPC (:4317)
       v
Tempo (porta 3200)
       |
       | Query via Grafana
       v
Grafana Explore -> Tempo
```

## Armazenamento

### Atual (lab)

```yaml
storage:
  trace:
    backend: local
    local:
      path: /var/tempo/traces
    wal:
      path: /var/tempo/wal
```

Armazenamento local no disco do pod. Sem persistencia (volatil).

### Producao (S3)

```yaml
storage:
  trace:
    backend: s3
    s3:
      bucket: meu-bucket-tempo-traces
      endpoint: s3.amazonaws.com
      region: us-east-1
```

## Buscando Traces no Grafana

### Via Service Name

```
Explore > Tempo > Search
Service Name: app-rds-dev
Min Duration: 1ms
Max Duration: 10s
```

### Via Tags (Span Attributes)

```
Explore > Tempo > Search
Tags:
  http.method: GET
  http.status_code: 200
```

### Via Trace ID

Se voce tem o traceId (vindo de um log ou header de resposta):

```
Explore > Tempo > Trace ID
Trace ID: 0af7651916cd43dd8448eb211c80319c
```

### Correlacao com Logs

No Grafana, voce pode clicar em um span do Tempo e ver "Related Logs" que mostra os logs do Loki para aquele trace:

```
[Span: POST /api/users] (tempo)
       |
       v
[Logs: {app="app-rds"} |= "traceID=0af7651916cd43dd8448eb211c80319c"] (loki)
```

Isso funciona porque o SDK OTel injeta o traceId nos logs automaticamente.

## Comandos Uteis

```bash
# Ver status do Tempo
kubectl get pods -n monitoring | grep tempo

# Port-forward para API do Tempo
kubectl port-forward -n monitoring svc/tempo 3200:3200

# Ver readiness
curl http://localhost:3200/ready

# Buscar traces via API
curl "http://localhost:3200/api/search?q={service.name=\"app-rds-dev\"}"

# Ver metricas do Tempo
curl http://localhost:3200/metrics
```

## Referencias

- [Documentacao Oficial](https://grafana.com/docs/tempo/latest/)
- [Tempo em Producao](https://grafana.com/docs/tempo/latest/setup/deployment/)
- [Armazenamento S3](https://grafana.com/docs/tempo/latest/configuration/manifest/backend/s3/)
- [Helm Chart](https://github.com/grafana/helm-charts/tree/main/charts/tempo)

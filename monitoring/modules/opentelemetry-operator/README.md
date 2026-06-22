# OpenTelemetry Operator

## Visao Geral

O OpenTelemetry Operator e um operador Kubernetes que gerencia o ciclo de vida de coletores OpenTelemetry e automatiza a instrumentacao de aplicacoes sem necessidade de modificar o codigo fonte.

## O que ele faz

### 1. Auto-Instrumentacao (o recurso mais importante)

O Operator injeta automaticamente o SDK do OpenTelemetry nos pods da sua aplicacao atraves de uma simples annotation:

```yaml
annotations:
  instrumentation.opentelemetry.io/inject-nodejs: "true"
```

**Sem precisar alterar o codigo!** O Operator:

1. Intercepta a criacao do pod via Mutating Webhook
2. Injeta um init container com o SDK OTel
3. Configura variaveis de ambiente (OTEL_EXPORTER_OTLP_ENDPOINT, OTEL_SERVICE_NAME)
4. O SDK captura automaticamente: HTTP, gRPC, SQL, Redis, etc

### 2. Gerenciamento de Coletores (CRD OpenTelemetryCollector)

Permite definir e gerenciar coletores OTel via recursos Kubernetes:

```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: meu-coletor
spec:
  mode: deployment
  config: |
    receivers:
      otlp:
        protocols:
          grpc:
          http:
    processors:
      batch:
    exporters:
      otlp:
        endpoint: tempo:4317
```

### 3. Gerenciamento de Instrumentacao (CRD Instrumentation)

Centraliza a configuracao de auto-instrumentacao:

```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: Instrumentation
metadata:
  name: default-instrumentation
spec:
  exporter:
    endpoint: http://otel-collector:4317
  propagators:
    - tracecontext
    - baggage
  sampler:
    type: parentbased_traceidratio
    argument: "1.0"
  nodejs:
    env:
      - name: OTEL_SERVICE_NAME
        value: "app-${POD_NAME}"
```

## Linguagens Suportadas para Auto-Instrumentacao

| Linguagem | Annotation | SDK Utilizado |
|-----------|-----------|---------------|
| Node.js | inject-nodejs | @opentelemetry/auto-instrumentations-node |
| Python | inject-python | opentelemetry-instrumentation |
| Java | inject-java | OpenTelemetry Java Agent |
| .NET | inject-dotnet | OpenTelemetry .NET |
| Go | Atraves de SDK manual | opentelemetry-go |

## Arquitetura

```
                    kubectl apply -f deployment.yaml
                              |
                              v
                    +---------------------+
                    |  Mutating Webhook   |
                    |  (Operator)         |
                    +---------------------+
                              |
                    Intercepta criacao do pod
                              |
                    Injeta init container SDK
                              |
                              v
                    +---------------------+
                    |  Pod da Aplicacao   |
                    |                     |
                    |  [Init Container]   |
                    |  SDK OpenTelemetry  |
                    |                     |
                    |  [Main Container]   |
                    |  Sua App (pura)     |
                    +---------------------+
                              |
                    Envia telemetria OTLP
                              |
                              v
                    +---------------------+
                    |  OTEL Collector     |
                    +---------------------+
```

## Como testar a auto-instrumentacao

```bash
# 1. Verificar se o Operator esta rodando
kubectl get pods -n monitoring | grep opentelemetry-operator

# 2. Criar um deployment com a annotation
kubectl run test-otel --image=nginx --annotations="instrumentation.opentelemetry.io/inject-nodejs=true"

# 3. Verificar se o init container foi injetado
kubectl describe pod test-otel | grep Init

# 4. Ver os traces no Grafana
# kubectl -n monitoring port-forward svc/grafana 3000:80
# Explore > Tempo > Search
```

## Referencias

- [Documentacao Oficial](https://opentelemetry.io/docs/kubernetes/operator/)
- [GitHub do Operator](https://github.com/open-telemetry/opentelemetry-operator)
- [Auto-Instrumentacao](https://opentelemetry.io/docs/kubernetes/operator/automatic/)

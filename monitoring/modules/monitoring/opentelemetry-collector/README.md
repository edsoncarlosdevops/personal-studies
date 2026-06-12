# OpenTelemetry Collector

## Visao Geral

O OpenTelemetry Collector e um agente/proxy que recebe, processa e exporta dados de telemetria (traces, metricas, logs). Ele e o componente central do pipeline de observabilidade.

## Pipeline de Dados

O Collector funciona em 3 etapas:

```
[Dados] -> RECEIVERS -> PROCESSORS -> EXPORTERS -> [Backends]
```

### 1. RECEIVERS (Entrada)

Como os dados chegam no Collector:

| Receptor | Protocolo | Porta | Descricao |
|----------|-----------|-------|-----------|
| otlp (gRPC) | OTLP | 4317 | Recebe dados do SDK OTel (mais performatico) |
| otlp (HTTP) | OTLP | 4318 | Recebe dados via HTTP/JSON |
| prometheus | - | - | Faz scraping em endpoints /metrics |
| kubeletstats | - | 10250 | Coleta metricas do Kubelet |

### 2. PROCESSORS (Processamento)

O que o Collector faz com os dados antes de enviar:

| Processor | Funcao | Producao? |
|-----------|--------|-----------|
| batch | Agrupa spans/metrics para reduzir chamadas de rede | Essencial |
| memory_limiter | Evita crash por OOM (Out of Memory) | Essencial |
| k8sattributes | Adiciona metadata do K8s (pod, namespace, deployment) | Recomendado |
| resourcedetection | Detecta ambiente (AWS, EKS, EC2) | Recomendado |
| filter | Filtra dados indesejados | Opcional |
| transform | Modifica atributos dos spans | Opcional |

### 3. EXPORTERS (Saida)

Para onde os dados sao enviados:

| Exporter | Destino | Funcao |
|----------|---------|--------|
| otlp | Tempo (:4317) | Envia traces para o Tempo |
| prometheus | :8889 | Expoe metricas para o Prometheus raspar |
| loki (OTLP) | Loki (:3100/otlp/v1/logs) | Envia logs para o Loki |
| prometheusremotewrite | Grafana Cloud / AMP | Envia metricas para cloud |

## Modos de Deploy

### Mode: deployment (ATUAL - Recomendado para lab)

```
[Apps] -> [Collector Centralizado] -> [Tempo + Prometheus]
```

- Um unico collector para todo o cluster
- Facil de gerenciar
- Ponto unico de configuracao
- Bom para labs e ambientes pequenos

### Mode: daemonset (Recomendado para producao)

```
[App Pod A] -> [Collector Pod A] (mesmo node)
[App Pod B] -> [Collector Pod B] (mesmo node)
                      |
                      v
            [Tempo + Prometheus Central]
```

- Um collector por node
- Melhor isolamento
- Coleta metricas do host
- Ideal para producao com alto volume

### Mode: statefulset

```
[Collector Pod-0] -> estado persistente
[Collector Pod-1] -> estado persistente
```

- Identidade persistente por pod
- Bom para coletores com estado
- Raramente usado

## Configuracao Atual (values.yaml)

### Receivers habilitados:
- **OTLP gRPC** (:4317) - para SDKs das aplicacoes
- **OTLP HTTP** (:4318) - fallback HTTP

### Processors habilitados:
- **batch** - agrupa spans/metrics

### Exporters habilitados:
- **OTLP** -> Tempo (traces)
- **Prometheus** -> :8889 (metricas)
- **Loki (OTLP)** -> :3100/otlp/v1/logs (logs)

### Sugestoes para producao (comentadas no values.yaml):
- Descomentar memory_limiter (evitar OOM)
- Descomentar k8sattributes (enriquecer dados)
- Descomentar resourcedetection (identificar EKS)
- Configurar prometheusremotewrite para Grafana Cloud

## Portas Expostas

| Porta | Protocolo | Uso |
|-------|-----------|-----|
| 4317 | gRPC | Receber dados OTLP das apps |
| 4318 | HTTP | Receber dados OTLP via HTTP |
| 8888 | HTTP | Metricas do proprio Collector |
| 8889 | HTTP | Endpoint Prometheus para scraping |

## Fluxo Atual no Projeto

```
     Apps com SDK OTel
           |
           v (OTLP gRPC :4317)
     OTEL Collector (deployment)
           |
   +---+---+-------+
   |       |       |
   v       v       v
 Tempo   Prometheus  Loki
(traces) (:8889)    (OTLP HTTP)
         (metricas)  (logs)
   |       |       |
   +---+---+---+
       |
       v
   Grafana
```

> O OpenTelemetry SDK coleta os 3 pilares (traces, metricas, logs) e envia tudo via OTLP para o Collector, que roteia para os backends corretos. **Nenhum agente externo (Promtail, Fluentd, etc.) é necessario.**

## Como testar

```bash
# Verificar se o Collector esta rodando
kubectl get pods -n monitoring | grep opentelemetry-collector

# Ver logs do Collector
kubectl logs -n monitoring -l app.kubernetes.io/name=opentelemetry-collector

# Testar envio de trace manual
kubectl run curl --image=curlimages/curl -it --rm -- sh
/ $ curl -X POST http://opentelemetry-collector.monitoring:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{"resourceSpans":[]}'

# Ver metricas do Collector
kubectl port-forward -n monitoring svc/opentelemetry-collector 8888:8888
curl http://localhost:8888/metrics
```

## Referencias

- [Documentacao Oficial](https://opentelemetry.io/docs/collector/)
- [Github - opentelemetry-collector-contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib)
- [Configuracoes Avancadas](https://opentelemetry.io/docs/collector/configuration/)

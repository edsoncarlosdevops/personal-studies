# 📊 Stack de Observabilidade - Kubernetes (EKS)

Stack completa de observabilidade para Kubernetes rodando em **AWS EKS**, utilizando o ecossistema **OpenTelemetry** para coleta de traces e métricas, e **Grafana + Prometheus + Loki + Tempo** para visualização e análise.

---

## 🧭 Índice

- [Arquitetura](#arquitetura)
- [Pré-requisitos](#pré-requisitos)
- [Componentes](#componentes)
- [Quick Start](#quick-start)
- [Telemetria: Métricas, Logs e Traces](#telemetria-métricas-logs-e-traces)
- [Auto-Instrumentação (OTel Operator)](#auto-instrumentação-otel-operator)
- [SLOs (Service Level Objectives)](#slos-service-level-objectives)
- [Dashboards](#dashboards)
- [Alertas](#alertas)
- [Perguntas Frequentes](#perguntas-frequentes)

---

## Arquitetura

```
┌─────────────────────────────────────────────────────────────────┐
│                        APLICAÇÕES                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │  App Python  │  │  App Node.js │  │  Outros Serviços     │   │
│  │  (Flask/HTTP)│  │  (Express)   │  │  (Java, Go, .NET...) │   │
│  └──────┬───────┘  └─────┬─-──────┘  └─────────┬──────────-─┘   │
│         │ Auto-Instr     │ Auto-Instr          │ Auto-Instr     │
│         │ Python (0.60)  │ Node.js (0.69)      │ (conforme      │
│         │                │                     │  linguagem)    │
└─────────┼────────────────┼─────────────────────┼──────────────-─┘
          │                │                     │
          ▼                ▼                     ▼
     ┌─────────────────────────────────────────────────---┐
     │          OpenTelemetry Collector                   │
     │  ┌──────────-┐  ┌──────────-┐  ┌────────────────-┐ │
     │  │ OTLP gRPC │  │ OTLP HTTP │  │  Jaeger/Zipkin  │ │
     │  │ :4317     │  │ :4318     │  │  :14250/:9411   │ │
     │  └──────────-┘  └──────────-┘  └────────────────-┘ │
     │                                                    │
     │  Processors: memory_limiter → batch                │
     └────────────────────┬──-─────────────────────────---┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
   ┌──────────┐    ┌──────────┐    ┌──────────┐
   │  Tempo   │    │ Loki     │    │Prometheus│
   │ (Traces) │    │ (Logs)   │    │(Métricas)│
   └────┬─────┘    └────┬─────┘    └────┬─────┘
        │               │               │
        └───────────────┼───────────────┘
                        ▼
                 ┌──────────┐
                 │  Grafana │
                 │ (Dashboards + Alertas) │
                 └──────────┘
```

### Fluxo de Dados

| Dado | Coleta | Armazenamento | Visualização |
|------|--------|---------------|--------------|
| **Traces** | OTel SDK / Auto-Instrumentação | Tempo | Grafana (Tempo datasource) |
| **Logs** | Grafana Agent (PodLogs CRD) | Loki | Grafana (Loki datasource) |
| **Métricas** | Prometheus + cAdvisor + kube-state-metrics | Prometheus | Grafana (Prometheus datasource) |

---

## Pré-requisitos

| Ferramenta | Versão Mínima | Motivo |
|------------|---------------|--------|
| Kubernetes | 1.27+ | Suporte a CRDs e webhooks |
| Helm | 3.12+ | Instalação dos charts |
| kubectl | 1.27+ | Gerenciamento do cluster |
| AWS CLI | 2.x | Acesso ao EKS |

---

## Componentes

| Componente | Versão | Função |
|------------|--------|--------|
| **OpenTelemetry Operator** | 0.144.0 | Gerenciamento de auto-instrumentação e collectors |
| **OpenTelemetry Collector** | 0.112.0 | Receptor/processador/exportador de telemetria |
| **Tempo** | 2.3.0 | Armazenamento de traces distribuídos |
| **Loki** | 2.9.3 | Armazenamento de logs |
| **Grafana** | 12.1.0 | Dashboards e alertas |
| **Prometheus** | 2.x | Métricas e alertas |
| **Cert-Manager** | - | Certificados TLS dos webhooks |

---

## Quick Start

```bash
# 1. Acessar o cluster
aws eks update-kubeconfig --region us-east-1 --name <cluster-name>

# 2. Aplicar a stack de observabilidade
cd deploy/monitoring
terraform init
terraform plan
terraform apply

# 3. Acessar o Grafana
kubectl port-forward -n monitoring svc/grafana 8080:80
# Acesse: http://localhost:8080 (admin / admin)

# 4. Verificar se os dados estão chegando
kubectl exec -n monitoring deployment/app-traces -- python -c "
import requests
r = requests.get('http://tempo.monitoring.svc.cluster.local:3100/api/search?limit=5')
print(f'Traces no Tempo: {len(r.json().get(\"traces\", []))}')
"
```

---

## Telemetria: Métricas, Logs e Traces

### Métricas (Prometheus)

Coletadas automaticamente pelo Prometheus via:

| Fonte | Job | Porta |
|-------|-----|-------|
| cAdvisor (containers) | `kubernetes-cadvisor` | 443 (kubelet) |
| kube-state-metrics | `kube-state-metrics` | 8080 |
| Node Exporter | `kubernetes-nodes` | 9100 |
| OTel Collector | `opentelemetry-collector` | 8888 |

### Logs (Loki)

Coletados via **Grafana Agent** usando o CRD `PodLogs`:

```yaml
apiVersion: monitoring.grafana.com/v1alpha1
kind: PodLogs
metadata:
  name: loki
  namespace: monitoring
spec:
  namespaceSelector: {}      # Coleta de TODOS os namespaces
  pipelineStages:
    - cri: {}
  selector:
    matchLabels:
      app.kubernetes.io/instance: loki
      app.kubernetes.io/name: loki
```

> 💡 **Dica:** Para excluir namespaces de sistema, use `matchExpressions`:
> ```yaml
> namespaceSelector:
>   matchExpressions:
>     - key: kubernetes.io/metadata.name
>       operator: NotIn
>       values:
>         - kube-system
>         - kube-public
>         - kube-node-lease
> ```

### Traces (Tempo)

Os traces são enviados ao **OpenTelemetry Collector** que encaminha ao Tempo:

| Protocolo | Porta | Uso |
|-----------|-------|-----|
| OTLP gRPC | 4317 | SDK manual (ex: app-traces) |
| OTLP HTTP | 4318 | Auto-instrumentação |

---

## Auto-Instrumentação (OTel Operator)

### Como funciona

O **OpenTelemetry Operator** injeta automaticamente o código de instrumentação nos seus pods **sem modificar o código da aplicação**. Ele faz isso via:
1. **Webhook** que intercepta a criação de pods
2. **Init container** que copia os binários/scripts de instrumentação
3. **Variáveis de ambiente** que configuram o SDK

### Aplicações testadas

| Linguagem | Imagem | Annotation |
|-----------|--------|------------|
| Python 3.11 | `python:3.11-slim` | `instrumentation.opentelemetry.io/inject-python: "monitoring/python-instrumentation"` |
| Node.js 20 | `node:20-slim` | `instrumentation.opentelemetry.io/inject-nodejs: "monitoring/nodejs-instrumentation"` |
| Java | `eclipse-temurin:17` | `instrumentation.opentelemetry.io/inject-java: "monitoring/java-instrumentation"` |
| .NET | `mcr.microsoft.com/dotnet/aspnet:8.0` | `instrumentation.opentelemetry.io/inject-dotnet: "monitoring/dotnet-instrumentation"` |

### Como usar

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: meu-servico
  namespace: production
spec:
  template:
    metadata:
      annotations:
        instrumentation.opentelemetry.io/inject-python: "monitoring/python-instrumentation"
    spec:
      containers:
      - name: app
        image: meu-servico:latest
```

### Troubleshooting

**Problema: O pod só tem 1 container**
- ✅ Normal! O Operator 0.144.0+ usa **init container + env vars**, não sidecar

**Problema: Múltiplos Instrumentation CRs no mesmo namespace**
- ✅ Use annotation completa: `"monitoring/nome-do-instrumentation"` em vez de `"true"`

**Problema: Traces não aparecem no Tempo**
- Verifique se o `OTEL_EXPORTER_OTLP_ENDPOINT` está correto
- Verifique os logs do Collector: `kubectl logs -n monitoring deployment/opentelemetry-collector`

---

## SLOs (Service Level Objectives)

### Conceitos: SLI vs SLO vs SLA

```
SLI (Service Level Indicator)  →  O que medimos (a métrica)
SLO (Service Level Objective)  →  A meta que definimos
SLA (Service Level Agreement)  →  O contrato com o cliente
```

**Exemplo prático (testado no cluster):**

| Conceito | Nosso exemplo |
|----------|---------------|
| **SLI** | `avg(up{namespace="monitoring"})` = % de pods rodando |
| **SLO** | Disponibilidade > 95% (se cair, alerta dispara) |
| **SLA** | Notificar time via Slack/Email/PagerDuty |

### Como testamos na prática

```bash
# 1. Derrubamos um serviço propositalmente
kubectl scale deployment -n monitoring app-python-auto --replicas=0

# 2. O SLI caiu (métrica de disponibilidade)
#    Antes: 21/24 pods RUNNING (100%)
#    Depois: 20/24 pods RUNNING (83.3%)

# 3. O SLO foi violado (meta era > 95%)
#    Alerta disparou no Grafana Alerting

# 4. Recuperamos o serviço
kubectl scale deployment -n monitoring app-python-auto --replicas=1
```

### SLOs configurados

Regras de alerta definidas em `modules/prometheus/config/values.yaml` (grupo `slo`):

| SLO | SLI (métrica) | Meta | Severidade | Janela |
|-----|--------------|------|------------|--------|
| 📊 Disponibilidade | `avg(up{namespace="monitoring"})` | > 95% | 🔴 Critical | 2 min |
| 🔄 Confiabilidade | Pods em CrashLoopBackOff | Zero pods | 🟡 Warning | 1 min |
| 💾 Memória | working_set_bytes / request | < 85% | 🟡 Warning | 5 min |
| ⚡ CPU | usage / request | < 85% | 🟡 Warning | 5 min |

### Onde visualizar

- **Alertas SLO ativos:** `http://localhost:8080/alerting/list` (grupo "SLO")
- **Dashboard:** `http://localhost:8080/d/295f6601/stack-de-observabilidade`
- **Notificações:** Alertmanager envia email para `edsoncarlos.ec40@gmail.com`

### Ferramentas de SLO usadas no mercado

| Ferramenta | Tipo | Uso |
|------------|------|-----|
| **Grafana Alerting** | Open Source | Alertas SLO (como configuramos aqui) |
| **Grafana SLO App** | Plugin | Dashboard dedicado de SLO |
| **Nob9** | SaaS | SLO como serviço gerenciado |
| **Datadog SLO** | SaaS | SLO nativo Datadog |
| **Google SRE** | Metodologia | Conceito SLI/SLO/SLA (SRE Book) |

### SLA (Service Level Agreement) - Exemplo de contrato

```
SERVICO: Plataforma de Pagamentos
┌─────────────────────────────────────────────────────┐
│  SLI           │  SLO          │  SLA               │
├─────────────────────────────────────────────────────┤
│  Latencia P95  │  < 500ms      │  Credito de 5%     │
│                │  em 99% do mes│  por violacao      │
├─────────────────────────────────────────────────────┤
│  Taxa de erro  │  < 1% (5xx)   │  Notificar em      │
│                │               │  < 15 min          │
├─────────────────────────────────────────────────────┤
│  Uptime        │  > 99.9%      │  Chamar squad em   │
│                │               │  < 5 min           │
└─────────────────────────────────────────────────────┘
```
| Memória | working_set_bytes / request | < 85% | Warning | 5 min |
| CPU | usage / request | < 85% | Warning | 5 min |

### Como visualizar no Grafana

```
Alerting > Alert Rules > SLO_-_Service_Level_Objectives
```

---

## Dashboards

| Dashboard | Fonte | Descrição |
|-----------|-------|-----------|
| **Stack de Observabilidade** | Grafana interno | Visão geral: CPU, memória, traces, logs |

Para acessar:
```bash
kubectl port-forward -n monitoring svc/grafana 8080:80
# http://localhost:8080/d/c95bf618/stack-de-observabilidade
```

---

## Alertas

Os alertas utilizam o **Alertmanager** embutido no Prometheus.

### Alertas configurados

| Alerta | Expressão | Severidade |
|--------|-----------|------------|
| PodCrashLoopBackOff | `kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff"} > 0` | Critical |
| PodRestartHigh | `increase(kube_pod_container_status_restarts_total[30m]) > 3` | Warning |
| NodeDiskSpace | `node_filesystem_avail_bytes / node_filesystem_size_bytes < 0.2` | Critical |
| SLO Disponibilidade | `avg(up) < 0.95` | Critical |

### Configurar notificações (Slack, Email, etc)

Editar `deploy/monitoring/alertmanager/values.yaml`:

```yaml
alertmanager:
  config:
    global:
      slack_api_url: "https://hooks.slack.com/services/..."
    receivers:
    - name: slack
      slack_configs:
      - channel: "#alerts"
    route:
      group_by: ['alertname', 'severity']
      receiver: slack
```

---

## Perguntas Frequentes

### Por que só vejo 2 namespaces no Loki?

Verifique se o `PodLogs` está configurado para coletar de todos os namespaces:
```bash
kubectl get podlogs -n monitoring loki -o yaml | grep namespaceSelector
# Deve ser: namespaceSelector: {}
```

### Como adicionar um novo serviço à stack?

Apenas adicione a annotation correspondente à linguagem no deployment:
```yaml
annotations:
  instrumentation.opentelemetry.io/inject-python: "monitoring/python-instrumentation"
```

### O auto-instrumentation funciona com qualquer framework?

**Python:** Flask, Django, FastAPI, requests, urllib, etc.
**Node.js:** Express, http, fetch, etc.
**Java:** Spring Boot, JAX-RS, gRPC, JDBC, etc.
**.NET:** ASP.NET Core, HttpClient, Entity Framework, etc.

[Lista completa de instrumentações suportadas](https://opentelemetry.io/docs/kubernetes/operator/automatic/)

### Preciso modificar o código da minha aplicação?

**Não!** A auto-instrumentação via OTel Operator **não requer modificação no código**. Você só precisa adicionar a annotation no deployment.

---

## Estrutura do Projeto

```
monitoring/
├── README.md
├── deploy/
│   └── monitoring/
│       ├── alertmanager/
│       ├── grafana/
│       ├── loki/
│       ├── opencost/
│       ├── opentelemetry-collector/
│       ├── opentelemetry-operator/
│       ├── prometheus/
│       └── tempo/
├── modules/
│   └── monitoring/
├── dashboards/
│   ├── observabilidade-stack.json
│   └── slo-rules.yml
└── tests/
```

---

## Referências

- [OpenTelemetry Operator](https://opentelemetry.io/docs/kubernetes/operator/)
- [Grafana Tempo](https://grafana.com/oss/tempo/)
- [Prometheus Alerting Rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)
- [SLO - Google SRE Book](https://sre.google/sre-book/service-level-objectives/)

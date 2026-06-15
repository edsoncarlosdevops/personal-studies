# Observability Stack on Azure (AKS)

Full observability stack deployed on **Azure Kubernetes Service** using **Terraform**, **Terragrunt**, and **GitHub Actions**.

---

## Architecture Overview

```
Azure (eastus2)
└── rg-observability
    ├── vnet-observability (10.0.0.0/16)
    │   ├── snet-aks               → AKS nodes
    │   ├── snet-postgresql        → PostgreSQL Flexible Server
    │   └── snet-private-endpoints → Private endpoints
    ├── AKS: aks-observability (K8s 1.30)
    └── PostgreSQL Flexible Server

AKS Cluster (namespace: monitoring)
├── cert-manager            → TLS
├── Prometheus + Alertmanager → Metrics & alerts
├── Grafana                → Dashboards
├── Loki + Promtail        → Logs
├── Tempo                  → Traces
├── OpenTelemetry Operator → Auto-instrumentation
├── OpenTelemetry Collector → Pipeline (metrics→Prometheus, traces→Tempo, logs→Loki)
├── OpenCost               → Cost monitoring
└── postgres-exporter      → PostgreSQL metrics
```

---

## Deploy Order

```
Step 1: AKS + VNet      (terragrunt apply)
Step 2: PostgreSQL       (terragrunt apply)
Step 3: Monitoring Stack (terragrunt run-all apply)
Step 4: App              (kubectl apply or GitHub Actions)
```

---

## Prerequisites

```bash
# Tools
terraform >= 1.5
terragrunt >= 0.72
az cli

# Azure login
az login
az account set --subscription "your-subscription"
```

---

## Deploy

```bash
# 1. AKS (infra + networking)
cd deploy/environments/dev/aks
terragrunt apply
cd ../..

# 2. PostgreSQL
cd postgresql
terragrunt apply
cd ..

# 3. Monitoring stack (respects dependencies automatically)
cd monitoring
terragrunt run-all apply
cd ../..

# 4. Deploy sample app
kubectl apply -f app-node/k8s/deployment.yaml
```

---

## Project Structure

```
observability-stack-azure/
├── .github/workflows/
│   ├── deploy-monitoring.yml    # CI/CD with SAST + Plan + Apply
│   └── app-node-ci.yml          # App CI (lint + SAST + tests)
├── alerts/
│   ├── config/alertmanager.yaml          # Email + Telegram
│   ├── prometheus-rules.yaml             # Pods, resources, app
│   └── prometheus-rules-postgresql.yaml  # PostgreSQL alerts
├── app-node/                   # Sample Node.js app
│   ├── src/server.js           # Express (3 endpoints)
│   ├── Dockerfile
│   └── k8s/deployment.yaml     # With OTel annotation
├── dashboards/
│   └── postgresql-overview.json  # Grafana dashboard
├── deploy/
│   ├── terragrunt.hcl          # Global provider config
│   └── environments/dev/
│       ├── aks/                # AKS + VNet
│       ├── postgresql/         # Azure PostgreSQL
│       ├── locals.tf           # Shared variables
│       └── monitoring/         # 10 components
├── modules/
│   ├── aks/                    # AKS module (real)
│   ├── postgresql/             # PostgreSQL module (real)
│   └── monitoring/             # Wrappers → monitoring/modules/monitoring/
└── monitoring/                 # Real modules (separate repo)
```

---

## Monitoring Pipelines

```
OpenTelemetry Collector:
  Metrics → Prometheus (port 8889, prefix "otel_")
  Traces  → Tempo (http://tempo.monitoring.svc:4317)
  Logs    → Loki (http://loki.monitoring.svc:3100)

postgres-exporter:
  Metrics → Prometheus (scraped via ServiceMonitor)
```

---

## Alerts

| Alert | Severity | Description |
|-------|----------|-------------|
| PodCrashLoopBackOff | critical | Pod in crash loop |
| PodRestartHigh | warning | >3 restarts in 30min |
| PodNotReady | critical | Pod not ready for 5min |
| HighCPUUsage | warning | CPU >80% for 10min |
| HighMemoryUsage | warning | Memory >80% for 10min |
| HighRequestLatency | warning | P95 latency >500ms |
| HighErrorRate | critical | Error rate >5% |
| PostgreSQLDown | critical | Server unreachable |
| PostgreSQLHighConnections | warning | >80 active connections |
| PostgreSQLDeadlocks | critical | Deadlocks detected |
| PostgreSQLCacheHitRatio | warning | Cache hit <90% |

---

## CI/CD (GitHub Actions)

```yaml
On PR: SAST (TruffleHog + Checkov + TFSec) + Terragrunt Plan
On manual dispatch "apply": Approval gate → Terragrunt Apply
```

---

## Quick Commands

```bash
# Validate everything
terragrunt run-all validate

# Plan all
terragrunt run-all plan

# Plan a single component
terragrunt plan --terragrunt-working-dir deploy/environments/dev/aks

# Apply all
terragrunt run-all apply

# Destroy all
terragrunt run-all destroy
```

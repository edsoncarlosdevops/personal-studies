# Observability Stack on Azure (AKS)

Full observability stack deployed on **Azure Kubernetes Service** using **Terraform**, **Terragrunt**, and **OpenTelemetry**.

---

## Architecture

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
├── cert-manager               → TLS
├── Prometheus + Alertmanager  → Metrics & alerts
├── Grafana                    → Dashboards
├── Loki + Promtail            → Logs
├── Tempo                      → Traces
├── OpenTelemetry Operator     → Auto-instrumentation
├── OpenTelemetry Collector    → Pipeline (metrics, traces, logs)
├── OpenCost                   → Cost monitoring
└── postgres-exporter          → PostgreSQL metrics
```

---

## Prerequisites

```bash
# Tools
brew install terraform terragrunt kubectl azure-cli

# Azure login
az login --tenant e350a4aa-300d-4d3d-8723-9e5554b17f3a
az account set --subscription "Azure subscription 1"
```

---

## Deploy

### Step 1: Bootstrap (one time only)

Creates the remote state backend: Resource Group + Storage Account + Blob Container.

```bash
cd modules/bootstrap
terraform init
terraform apply -auto-approve
```

No input needed. The storage account name is auto-generated with a random suffix.

### Step 2: Deploy the stack

```bash
cd deploy/environments/dev
terragrunt run-all plan    # Preview
terragrunt run-all apply   # Create everything
```

This creates in order:

| Order | Component | What it does |
|-------|-----------|-------------|
| 1 | **AKS + VNet** | Resource Group, VNet, subnets, NSG, AKS cluster |
| 2 | **PostgreSQL** | Azure Database for PostgreSQL Flexible Server |
| 3 | **Monitoring** | 12 components (Prometheus, Grafana, Loki, etc.) |

### Step 3: Access the cluster

```bash
az aks get-credentials --resource-group rg-observability --name aks-observability
kubectl get nodes
kubectl get pods -n monitoring
```

---

## Destroy

```bash
cd deploy/environments/dev
terragrunt run-all destroy
```

> No protection locks — `prevent_deletion_if_contains_resources = false` is configured.

---

## Project Structure

```
├── modules/
│   ├── bootstrap/       → Remote state backend (RG + Storage + Container)
│   ├── aks/             → AKS + VNet + subnets + NSG
│   └── postgresql/      → Azure PostgreSQL Flexible Server
├── deploy/
│   ├── terragrunt.hcl   → Global config (providers, remote state)
│   └── environments/dev/
│       ├── aks/         → AKS terragrunt
│       ├── postgresql/  → PostgreSQL terragrunt
│       ├── locals.tf    → Shared variables
│       └── monitoring/  → 12 monitoring components
├── app-node/            → Sample Node.js app (Express + OTel annotation)
├── alerts/              → Prometheus rules + Alertmanager config
├── dashboards/          → Grafana dashboards (JSON)
└── scripts/             → Utility scripts
```

## Alerts

| Alert | Severity | Description |
|-------|----------|-------------|
| PodCrashLoopBackOff | critical | Pod in crash loop |
| PodRestartHigh | warning | >3 restarts in 30min |
| PodNotReady | critical | Pod not ready for 5min |
| NodeDiskSpace | critical | Node disk <20% |
| NodeNotReady | critical | Node not ready |
| HighRequestLatency | warning | P95 latency >500ms |
| HighErrorRate | critical | HTTP 5xx >5% |
| PrometheusTargetDown | critical | Scrape target unreachable |
| PostgreSQLDown | critical | Server unreachable |
| PostgreSQLHighConnections | warning | >80 active connections |
| PostgreSQLDeadlocks | critical | Deadlocks detected |
| PostgreSQLCacheHitRatio | warning | Cache hit <90% |

## Notifications

Alerts are routed via **Alertmanager**:
- **Critical**: Email + Telegram
- **Warning**: Email only
- **Resolved**: Notified with status

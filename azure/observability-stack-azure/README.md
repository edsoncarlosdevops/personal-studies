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
brew install terraform terragrunt kubectl azure-cli
az login --tenant e350a4aa-300d-4d3d-8723-9e5554b17f3a
az account set --subscription "Azure subscription 1"
```

---

## Deploy

### 1. Bootstrap (one time only)

Creates remote state backend: Resource Group + Storage Account + Container.

```bash
cd bootstrap
terraform init
terraform apply -auto-approve
```

### 2. Deploy the stack

```bash
cd deploy/environments/dev
terragrunt run run-all plan    # Preview
terragrunt run run-all apply   # Create everything
```

### 3. Access the cluster

```bash
az aks get-credentials --resource-group rg-observability --name aks-observability
kubectl get nodes
kubectl get pods -n monitoring
```

---

## Destroy

```bash
cd deploy/environments/dev
terragrunt run run-all destroy
```

---

## Project Structure

```
├── bootstrap/               # Remote state setup (RG + Storage + Container)
├── modules/
│   ├── aks/                 # AKS + VNet + subnets + NSG
│   └── postgresql/          # Azure PostgreSQL Flexible Server
├── deploy/
│   ├── terragrunt.hcl       # Global config (providers, remote state)
│   └── environments/dev/
│       ├── aks/             # AKS deployment
│       ├── postgresql/      # PostgreSQL deployment
│       ├── locals.tf        # Shared variables
│       └── monitoring/      # 12 monitoring components
├── alerts/
│   ├── prometheus-rules.yaml             # Pod, node, app alerts
│   ├── prometheus-rules-postgresql.yaml  # PostgreSQL alerts
│   └── config/alertmanager.yaml          # Email + Telegram
├── dashboards/
│   └── postgresql-overview.json          # Grafana dashboard
├── app-node/                # Sample Node.js app
├── scripts/
│   └── generate-docs.sh     # Auto-doc generation
└── README.md
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

Alerts routed via **Alertmanager**:
- **Critical**: Email + Telegram
- **Warning**: Email only
- **Resolved**: Notified with status

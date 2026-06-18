# Observability Stack on Azure (AKS)

Full observability stack deployed on **Azure Kubernetes Service**.

**Infra (Azure):** Terraform puro  
**Apps (K8s):** Terragrunt (Helm charts)

Padrão similar ao [aws/eks_rds](../aws/eks_rds/).

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
az login
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

### 2. Infra Azure (AKS + PostgreSQL)

```bash
cd deploy/environments/dev/tf
terraform init
terraform apply
```

> AKS leva ~15 min para criar.

### 3. Monitoring (Helm charts via Terragrunt)

Cada componente individualmente:

```bash
cd deploy/environments/dev/monitoring/prometheus
terragrunt run apply

cd ../grafana
terragrunt run apply

# ... repeat for each component
```

### 4. Access the cluster

```bash
az aks get-credentials --resource-group rg-observability --name aks-observability
kubectl get nodes
kubectl get pods -n monitoring
```

---

## Destroy

### 1. Destroy monitoring

```bash
cd deploy/environments/dev/monitoring/prometheus
terragrunt run destroy

# ... repeat for each component
```

### 2. Destroy infra Azure

```bash
cd deploy/environments/dev/tf
terraform destroy
```

### 3. Destroy bootstrap (optional)

```bash
cd bootstrap
terraform destroy
```

---

## Project Structure

```
├── bootstrap/               # Remote state setup (RG + Storage + Container)
├── modules/
│   ├── aks/                 # AKS + VNet + subnets + NSG
│   └── postgresql/          # Azure PostgreSQL Flexible Server
├── deploy/
│   └── environments/dev/
│       ├── tf/              # 🟢 Infra Azure — Terraform puro (AKS + PostgreSQL)
│       │   ├── main.tf      #   → igual aws/eks_rds/environments/dev/main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── monitoring/      # 🟡 K8s apps — Terragrunt (Helm charts)
│       │   ├── terragrunt.hcl  # Lê outputs do tf/ para providers K8s/Helm
│       │   ├── prometheus/
│       │   ├── grafana/
│       │   ├── loki/
│       │   ├── tempo/
│       │   └── ...
│       └── locals.tf        # Shared variables
├── alerts/
│   ├── prometheus-rules.yaml
│   ├── prometheus-rules-postgresql.yaml
│   └── config/alertmanager.yaml
├── dashboards/
│   └── postgresql-overview.json
├── app-node/                # Sample Node.js app
├── scripts/
│   └── generate-docs.sh
└── README.md
```

---

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

---

> Padrão: [aws/eks_rds](../aws/eks_rds/) — infra com Terraform puro, apps K8s com Terragrunt.

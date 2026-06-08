# eks + rds

infra completa de devops na aws com terraform.

## o que tem aqui

- **vpc** com subnets publicas e privadas, nat gateway
- **eks** cluster kubernetes 1.30 com node group
- **rds** postgresql 16.14
- **bastion** ec2 para acesso ao banco (psql)
- **argocd** instalado via helm no cluster

## como usar

```bash
cd environments/dev
terraform init
terraform apply
```

## acessando o cluster

```bash
aws eks update-kubeconfig --region us-east-1 --name dev-eks-cluster
kubectl get nodes
```

## acessando o banco

```bash
ssh -i bastion-key.pem ec2-user@<bastion_ip>
psql -h <rds_endpoint> -U dbadmin -d appdb
```

## argocd

```bash
kubectl get svc -n argocd argocd-server  # pegar o dns do loadbalancer
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d
```

login: admin / senha acima

## stack de monitoramento e observabilidade (terragrunt)

Stack completa de monitoramento instalada via **Terragrunt** no cluster EKS, acoplando os módulos existentes em `monitoring/modules/monitoring/`.

### componentes

| Componente | Descrição |
|---|---|
| **Prometheus** | Métricas e alertas |
| **Grafana** | Dashboards (já integrado com Prometheus, Loki e Tempo) |
| **Loki** | Logs agregados |
| **Tempo** | Tracing distribuído |
| **Alertmanager** | Gerenciamento de alertas |
| **OpenCost** | Custos do cluster |
| **OpenTelemetry Operator** | Operator para coleta de traces/métricas |
| **OpenTelemetry Collector** | Coleta e encaminha traces → Tempo e métricas → Prometheus |

### 🔗 fluxo dos dados

```
OpenTelemetry Collector
  ├── traces  → Tempo (:4317)
  └── metrics → Prometheus (:8889)

Grafana
  ├── Prometheus → http://prometheus-server:80
  ├── Loki       → http://loki:3100
  └── Tempo      → http://tempo:3200

OpenCost → Prometheus → http://prometheus-server.monitoring.svc.cluster.local
```

### deploy

```bash
# 1. (se já não fez) Sobe o cluster EKS
cd environments/dev
terraform apply
cd ../..

# 2. Configura o kubectl pro cluster EKS
aws eks update-kubeconfig --region us-east-1 --name dev-eks-cluster

# 3. Instala toda a stack de monitoramento via Terragrunt
cd deploy
terragrunt run-all apply
```

> ⚠️ O Terragrunt usa o contexto atual do `~/.kube/config`. Antes de aplicar, confirme que está no cluster certo:
> ```bash
> kubectl config current-context
> ```

### destroy

```bash
cd deploy
terragrunt run-all destroy
```

### acessando o grafana

```bash
kubectl -n monitoring port-forward svc/grafana 3000:80
```

Acesse `http://localhost:3000` e use as credenciais:
- **user**: admin
- **password**: admin (ou a senha gerada pelo Helm — veja com `kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 -d`)



# OpenCost

## Visao Geral

OpenCost e uma ferramenta open-source para monitoramento de custos de Kubernetes. Ele mostra quanto cada namespace, deployment, pod ou servico esta custando com base no consumo de CPU, memoria, storage e trafego de rede.

## O que ele faz no projeto

OpenCost se conecta ao Prometheus para obter metricas de uso de recursos e, dependendo da configuracao, consulta APIs de precos do cloud provider (Azure, AWS, GCP) para calcular os custos reais.

## Arquitetura

```
OpenCost
    |
    +-> Prometheus
    |   (scrape: http://prometheus-server.monitoring.svc.cluster.local)
    |
    +-> APIs internas do cluster
    |   (kube-state-metrics)
    |
    +-> Cloud Provider Pricing API (se configurado)
    |   - Azure Retail Rates API
    |   - AWS Pricing API (automatico em EKS)
    |   - Google Cloud Billing API (automatico em GKE)
    |
    v
Interface Web (porta 9003) + API (porta 9003)
    |
    +-> Breakdown por:
        - Namespace
        - Deployment
        - Pod
        - Label
```

## Metricas de Custo

O OpenCost expoe metricas que o Prometheus pode raspar:

| Metrica | Descricao |
|---------|-----------|
| `node_cpu_hourly_cost` | Custo por CPU por hora |
| `node_gpu_hourly_cost` | Custo por GPU por hora |
| `node_ram_hourly_cost` | Custo por GB de RAM por hora |
| `pod_cost` | Custo total do pod |
| `deployment_cost` | Custo total do deployment |

## Como acessar

```bash
# Port-forward para UI do OpenCost
kubectl -n monitoring port-forward deployment/opencost 9003:9003

# Acessar
# http://localhost:9003

# UI tambem disponivel em:
# http://localhost:9090 (container opencost-ui, porta 9090)
```

## Configuracao de Precificacao (Pricing)

### Por que os custos estao em $0?

Se voce acessar o OpenCost e ver tudo zerado, e porque **nenhuma fonte de precos foi configurada**. O OpenCost precisa saber quanto cada recurso custa para calcular.

Ha 3 formas de configurar, em ordem de prioridade:

### 1. AZURE - Automatizado (recomendado para AKS)

O OpenCost consulta a **Azure Retail Rates API** para obter precos reais dos recursos.

**Passo a passo:**

```bash
# 1. Criar Service Principal com permissao de leitura
az ad sp create-for-rbac \
  --name "opencost-pricing" \
  --role "Reader" \
  --scope "/subscriptions/SUA_SUBSCRIPTION_ID"

# 2. Registrar provider de precos (se necessario)
az provider register --namespace Microsoft.Pricing

# 3. Copiar o output: appId, password, tenant
```

**No terragrunt.hcl**, descomente e preencha:

```hcl
opencost_azure_enabled          = true
opencost_azure_subscription_id  = "00000000-..."
opencost_azure_client_id        = "00000000-..."  # appId
opencost_azure_tenant_id        = "00000000-..."  # tenant
opencost_azure_client_secret    = "..."            # password
```

Aplique com `terragrunt apply` e o OpenCost passara a mostrar custos reais.

### 2. AWS - Automatico (EKS)

O OpenCost detecta automaticamente quando roda em EKS. Nao requer configuracao via Terraform.

**Requisitos:** O node role do EKS deve ter as permissoes IAM:
- `arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess`
- `arn:aws:iam::aws:policy/AWSPriceListServiceFullAccess`

Se o cluster ja usa EKS com essas policies, o OpenCost ja vai mostrar precos corretos automaticamente.

### 3. GCP - Automatico (GKE)

O OpenCost detecta automaticamente quando roda em GKE. Nao requer configuracao via Terraform.

**Requisitos:** Os nodes do GKE devem ter o escopo:
- `https://www.googleapis.com/auth/cloud-platform`

### 4. Custom Pricing (On-Premises / Local / Fallback)

Para ambientes sem cloud provider (kind, minikube, orbstack, on-premises), defina precos fixos.

**Via values.yaml** (ja comentado no arquivo):

```yaml
opencost:
  exporter:
    extraEnv:
      - name: CPU_COST_PER_HOUR
        value: "0.031611"
      - name: RAM_COST_PER_GB_HOUR
        value: "0.004237"
      - name: GPU_COST_PER_HOUR
        value: "0.70"
      - name: STORAGE_COST_PER_GB_HOUR
        value: "0.000054"
      - name: PV_COST_PER_GB_HOUR
        value: "0.000054"
      - name: LOAD_BALANCER_COST_PER_HOUR
        value: "0.025"
```

**Via arquivo JSON montado em /var/configs/pricing.json** (alternativa):

```json
{
  "CPU": 0.031611,
  "GPU": 0.70,
  "RAM": 0.004237,
  "STORAGE": 0.000054,
  "PV": 0.000054,
  "LOAD_BALANCER": 0.025
}
```

```bash
kubectl create configmap opencost-pricing \
  --namespace monitoring \
  --from-file=pricing.json
```

E adicione ao values.yaml:

```yaml
opencost:
  exporter:
    extraVolumes:
      - name: pricing-config
        configMap:
          name: opencost-pricing
    extraVolumeMounts:
      - name: pricing-config
        mountPath: /var/configs
```

## Comandos Uteis

```bash
# Port-forward para UI
kubectl -n monitoring port-forward deployment/opencost 9003:9003

# Ver metricas de custo via API
curl http://localhost:9003/allocation/compute

# Custo por namespace (ultimo dia)
curl "http://localhost:9003/allocation/compute?window=1d&aggregate=namespace"

# Custo por label
curl "http://localhost:9003/allocation/compute?window=7d&aggregate=label:app"

# Ver assets (nos, disks, etc)
curl http://localhost:9003/model/assets

# Ver precos configurados atualmente
curl http://localhost:9003/configs
```

## Troubleshooting

### Custos continuam em $0 apos configurar Azure

```bash
# 1. Verificar se as env vars estao no pod
kubectl -n monitoring exec deployment/opencost -- env | grep AZURE

# 2. Verificar logs do OpenCost
kubectl -n monitoring logs deployment/opencost opencost | grep -i "pricing\|azure\|cost"

# 3. Verificar config atual via API
kubectl -n monitoring port-forward deployment/opencost 9003:9003 &
curl http://localhost:9003/configs | jq .

# 4. Testar acesso a Azure Retail Rates API manualmente
# (dentro do pod ou localmente com as mesmas credenciais)
curl -X POST https://login.microsoftonline.com/{tenant}/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id={client_id}&client_secret={client_secret}&resource=https://management.azure.com"
```

## Referencias

- [Documentacao Oficial](https://www.opencost.io/docs/)
- [Helm Chart](https://github.com/opencost/opencost-helm-chart)
- [GitHub](https://github.com/opencost/opencost)
- [Azure Retail Rates API](https://docs.microsoft.com/en-us/azure/cost-management-billing/manage/ea-pricing)
- [AWS Pricing API](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/using-price-list.html)
- [Google Cloud Billing API](https://cloud.google.com/billing/docs/reference/rest)

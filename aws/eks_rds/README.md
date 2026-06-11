# EKS + RDS + Observabilidade

Infraestrutura completa de DevOps na AWS com Terraform, Terragrunt, Kubernetes, GitOps (ArgoCD) e Observabilidade Full Stack (OpenTelemetry, Prometheus, Grafana, Loki, Tempo).

---

## Indice

- [Arquitetura](#arquitetura)
- [Pre-requisitos](#pre-requisitos)
- [Infraestrutura Core (Terraform)](#infraestrutura-core-terraform)
- [Stack de Monitoramento (Terragrunt)](#stack-de-monitoramento-terragrunt)
- [Aplicacao CRUD (App RDS)](#aplicacao-crud-app-rds)
- [GitOps com ArgoCD](#gitops-com-argocd)
- [Fluxo de Dados de Observabilidade](#fluxo-de-dados-de-observabilidade)
- [Estrutura do Projeto](#estrutura-do-projeto)

---

## Arquitetura

```
Internet
    |
    +-- Bastion EC2 (acesso SSH ao RDS)
    |
    +-- EKS Cluster (K8s 1.30)
          |
          +-- Monitoring Stack (Terragrunt)
          |   +-- Prometheus       -> Metricas
          |   +-- Grafana          -> Dashboards
          |   +-- Loki             -> Logs
          |   +-- Tempo            -> Tracing
          |   +-- Alertmanager     -> Alertas
          |   +-- OpenCost         -> Custos
          |   +-- OTEL Operator    -> Auto-instrumentacao
          |   +-- OTEL Collector   -> Pipeline de telemetria
          |
          +-- App RDS (Node.js CRUD)
          |   +-- Conecta no RDS PostgreSQL
          |
          +-- ArgoCD (GitOps)
              +-- Sincroniza aplicacoes via Git

RDS PostgreSQL 16.14 (subnets privadas)
```

---

## Pre-requisitos

| Ferramenta | Versao |
|-----------|--------|
| Terraform | >= 1.6 |
| Terragrunt | >= 0.55 |
| AWS CLI | >= 2.x |
| kubectl | >= 1.30 |
| Docker | >= 24.x |

Conta AWS com permissoes para criar VPC, EKS, RDS, EC2 e IAM.

---

## Infraestrutura Core (Terraform)

### Componentes

| Componente | Modulo | Descricao |
|-----------|--------|-----------|
| VPC | modules/vpc/ | VPC 10.0.0.0/16, subnets publicas/privadas, NAT Gateway |
| EKS | modules/eks/ | Cluster Kubernetes 1.30, node group t3.medium (2-4 nos) |
| RDS | modules/rds/ | PostgreSQL 16.14, db.t3.micro, 20GB gp3, encrypted |
| Bastion | modules/bastion/ | EC2 jump host para acesso ao RDS |
| ArgoCD | modules/argocd/ | GitOps via Helm chart (v7.8.1) |
| App RDS | modules/app-rds/ | Aplicacao Node.js CRUD com conexao ao RDS |

### Deploy

```bash
cd environments/dev
terraform init
terraform apply
```

### Outputs

```bash
bastion_public_ip = "X.X.X.X"
eks_cluster_name  = "dev-eks-cluster"
rds_endpoint      = "dev-postgres.XXXXX.us-east-1.rds.amazonaws.com"
```

### Acessos

**Cluster EKS:**
```bash
aws eks update-kubeconfig --region us-east-1 --name dev-eks-cluster
kubectl get nodes
```

**Banco RDS (via Bastion):**
```bash
ssh -i bastion-key.pem ec2-user@<bastion_ip>
psql -h <rds_endpoint> -U dbadmin -d appdb
```

---

## Stack de Monitoramento (Terragrunt)

Stack completa de observabilidade instalada via Terragrunt no cluster EKS.

### Componentes

| Componente | Chart | Versao | Funcao |
|-----------|-------|--------|--------|
| Prometheus | prometheus | 27.1.0 | Metricas e alertas |
| Grafana | grafana | 9.3.2 | Dashboards |
| Loki | loki | 6.28.0 | Logs |
| Tempo | tempo | 1.7.1 | Tracing |
| Alertmanager | alertmanager | 1.8.0 | Alertas |
| OpenCost | opencost | 2.2.0 | Custos |
| OTEL Operator | opentelemetry-operator | 0.105.0 | Auto-instrumentacao |
| OTEL Collector | opentelemetry-collector | 0.105.0 | Pipeline de telemetria |
| Cert Manager | cert-manager | v1.16.0 | Certificados TLS |

### Auto-instrumentacao com OTEL Operator

O OTEL Operator injeta automaticamente o SDK nos pods com a annotation:

```yaml
annotations:
  instrumentation.opentelemetry.io/inject-nodejs: "true"
```

Sem modificar o codigo! Captura automaticamente:
- Requisicoes HTTP
- Queries SQL
- Chamadas gRPC

### Deploy

```bash
# 1. Configurar kubectl
aws eks update-kubeconfig --region us-east-1 --name dev-eks-cluster

# 2. Instalar monitoramento
cd deploy
terragrunt run-all apply
```

### Acessando o Grafana

```bash
kubectl -n monitoring port-forward svc/grafana 3000:80
```

Acesse http://localhost:3000 | user: admin | senha: `kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 -d`

---

## Aplicacao CRUD (App RDS)

Aplicacao Node.js que conecta no RDS PostgreSQL, instrumentada pelo OTEL Operator.

### Stack

| Tecnologia | Uso |
|-----------|-----|
| Node.js 20 | Runtime |
| Express 4.x | Framework web |
| pg 8.x | PostgreSQL |
| EJS 3.x | Frontend |

### Deploy

```bash
# 1. Build da imagem
cd deploy/apps/app-rds/src
docker build -t edsoncarlosdevops/app-rds:latest .
docker push edsoncarlosdevops/app-rds:latest

# 2. Editar deploy/apps/app-rds/terragrunt.hcl com os dados do RDS
#    db_endpoint, db_password

# 3. Deploy via Terragrunt
cd deploy/apps/app-rds
terragrunt apply

# 4. Testar
kubectl -n app-dev port-forward svc/app-rds 3000:3000
# http://localhost:3000
```

### Endpoints

| Metodo | Rota | Descricao |
|--------|------|-----------|
| GET | / | Pagina principal (HTML) |
| GET | /health | Health check |
| GET | /api/users | Listar usuarios (JSON) |
| POST | /api/users | Criar usuario (JSON) |
| DELETE | /api/users/:id | Deletar usuario (JSON) |
| POST | /users | Criar usuario (form) |
| POST | /api/users/:id/delete | Deletar usuario (form) |

---

## GitOps com ArgoCD

```bash
# 1. DNS do LoadBalancer
kubectl get svc -n argocd argocd-server

# 2. Senha do admin
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Acessar: https://<LB_DNS> | user: admin
```

Exemplos em `argocd-examples/`: root-app.yaml, applicationset.yaml, apps/

---

## Fluxo de Dados

```
App -> SDK OTEL (injetado pelo Operator)
        |
    OTEL Collector (grpc:4317 / http:4318)
        |
    +---+---+
    |       |
  Tempo  Prometheus
    |       |
    +---+---+
        |
     Grafana
  (Prometheus + Loki + Tempo)
```

---

## Estrutura do Projeto

```
aws/eks_rds/
+-- environments/dev/          (main.tf, provider.tf, outputs.tf)
+-- modules/
|   +-- vpc/                   (VPC, subnets, NAT Gateway)
|   +-- eks/                   (EKS cluster + node group)
|   +-- rds/                   (RDS PostgreSQL)
|   +-- bastion/               (Bastion EC2)
|   +-- argocd/                (ArgoCD Helm)
|   +-- app-rds/               (App Node.js CRUD)
+-- deploy/
|   +-- root.hcl               (config global Terragrunt)
|   +-- monitoring/             (9 componentes de observabilidade)
|   +-- apps/
|       +-- app-rds/
|           +-- terragrunt.hcl
|           +-- src/            (server.js, Dockerfile, templates/)
+-- argocd-examples/            (GitOps examples)
```

> Modulos helm em: `monitoring/modules/monitoring/` (raiz do repo)

---

## Clean Up

```bash
# Ordem: App -> Monitoring -> Infra
cd deploy/apps/app-rds && terragrunt destroy
cd deploy && terragrunt run-all destroy
cd environments/dev && terraform destroy
```

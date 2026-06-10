# ═══════════════════════════════════════════════════════════
# Providers - Ambiente Dev (EKS)
# ═══════════════════════════════════════════════════════════
#
# Provider Kubernetes/Helm:
# - Usa data.aws_eks_cluster e data.aws_eks_cluster_auth para
#   autenticar via AWS IAM, sem depender de kubeconfig local
# - Funciona no primeiro apply, após o cluster EKS ser criado
# - Basta rodar 'terraform apply' novamente após cluster criado
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Provider Kubernetes autenticando via AWS IAM (sem kubeconfig)
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
# Data sources para autenticação
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}


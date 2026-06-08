# ═══════════════════════════════════════════════════════════
# Providers - Ambiente Dev (EKS)
# ═══════════════════════════════════════════════════════════
#
# ATENÇÃO: Provider Kubernetes/Helm
# - Anteriormente usava data.aws_eks_cluster e data.aws_eks_cluster_auth
#   para autenticar via AWS IAM
# - MUDAMOS para config_path = "~/.kube/config" porque:
#   1. Evita erro "dial tcp localhost:80: connect: connection refused"
#      que ocorria ao tentar validar providers antes do EKS existir
#   2. Permite que o Terraform gerencie recursos K8s mesmo quando
#      o módulo EKS está sendo criado (depois do primeiro apply)
#   3. Funciona com 'aws eks update-kubeconfig' já configurado
#
# IMPORTANTE: Antes de rodar terraform apply pela primeira vez:
#   aws eks update-kubeconfig --region us-east-1 --name <cluster-name>

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

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}


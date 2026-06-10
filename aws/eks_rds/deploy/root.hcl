# ═══════════════════════════════════════════════════════
# Terragrunt Root - Deploy EKS
# ═══════════════════════════════════════════════════════
# Configuração global para deploy da stack de monitoramento no EKS.
# Usa data sources AWS em vez de kubeconfig para evitar erros de
# contexto. Os módulos filhos herdam estas configurações.
# ═══════════════════════════════════════════════════════

# Nome do cluster EKS - herdado dos inputs abaixo
locals {
  eks_cluster_name = "${include.root.locals.environment}-eks-cluster"
}

remote_state {
  backend = "local"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    path = "${path_relative_to_include()}/terraform.tfstate"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    # Provider gerado automaticamente pelo Terragrunt
    # Usa data sources AWS EKS para autenticar via IAM
    # sem depender de kubeconfig local

    data "aws_eks_cluster" "this" {
      name = "${local.eks_cluster_name}"
    }

    data "aws_eks_cluster_auth" "this" {
      name = "${local.eks_cluster_name}"
    }

    provider "kubernetes" {
      host                   = data.aws_eks_cluster.this.endpoint
      cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
      token                  = data.aws_eks_cluster_auth.this.token
    }

    provider "helm" {
      kubernetes = {
        host                   = data.aws_eks_cluster.this.endpoint
        cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
        token                  = data.aws_eks_cluster_auth.this.token
      }
    }
EOF
}

# Inputs globais
inputs = {
  environment = "dev"
  context     = "eks-dev"
  namespace   = "monitoring"
}

locals {
  # Extrai o environment dos inputs para usar no cluster name
  environment = "dev"
}


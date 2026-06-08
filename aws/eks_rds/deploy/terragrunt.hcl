# terragrunt.hcl raiz - Configuração global para deploy da stack de monitoramento no EKS
#
# ⚠️ ANTES DE USAR:
#   Verifique se o kubectl está apontando pro cluster EKS correto:
#     aws eks update-kubeconfig --region us-east-1 --name dev-eks-cluster
#     kubectl config current-context
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
  contents  = <<EOF
provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}
EOF
}

# Inputs globais
inputs = {
  context   = "eks-dev"
  namespace = "monitoring"
}


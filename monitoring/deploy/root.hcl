# ~/meu-lab-local/deploy/terragrunt.hcl

remote_state {
  backend = "local"
  
  # ADICIONE ESTAS LINHAS AQUI:
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
  config_path    = "~/.kube/config"
  config_context = "orbstack"
}

provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = "orbstack"
  }
}
EOF
}

# Inputs globais (opcional, mantenha se já tiver)
inputs = {
  context   = "local-lab"
  namespace = "monitoring"
}

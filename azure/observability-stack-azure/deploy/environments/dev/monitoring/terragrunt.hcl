# Monitoring Terragrunt config
# Lê outputs do Terraform (tf/) para configurar providers K8s/Helm

dependency "aks" {
  config_path = "../tf"
}

generate "k8s_provider" {
  path      = "k8s-provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "kubernetes" {
      host                   = dependency.aks.outputs.kube_config[0].host
      client_certificate     = base64decode(dependency.aks.outputs.kube_config[0].client_certificate)
      client_key             = base64decode(dependency.aks.outputs.kube_config[0].client_key)
      cluster_ca_certificate = base64decode(dependency.aks.outputs.kube_config[0].cluster_ca_certificate)
    }

    provider "helm" {
      kubernetes {
        host                   = dependency.aks.outputs.kube_config[0].host
        client_certificate     = base64decode(dependency.aks.outputs.kube_config[0].client_certificate)
        client_key             = base64decode(dependency.aks.outputs.kube_config[0].client_key)
        cluster_ca_certificate = base64decode(dependency.aks.outputs.kube_config[0].cluster_ca_certificate)
      }
    }
  EOF
}

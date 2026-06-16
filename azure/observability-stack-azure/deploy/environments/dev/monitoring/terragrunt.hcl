# Shared config for all monitoring components
# Includes K8s + Helm providers with AKS data source

include "root" {
  path = find_in_parent_folders()
}

generate "k8s_provider" {
  path      = "k8s-provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    data "azurerm_kubernetes_cluster" "this" {
      name                = "aks-observability"
      resource_group_name = "rg-observability"
    }

    provider "kubernetes" {
      host                   = data.azurerm_kubernetes_cluster.this.kube_config.0.host
      client_certificate     = base64decode(data.azurerm_kubernetes_cluster.this.kube_config.0.client_certificate)
      client_key             = base64decode(data.azurerm_kubernetes_cluster.this.kube_config.0.client_key)
      cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.this.kube_config.0.cluster_ca_certificate)
    }

    provider "helm" {
      kubernetes {
        host                   = data.azurerm_kubernetes_cluster.this.kube_config.0.host
        client_certificate     = base64decode(data.azurerm_kubernetes_cluster.this.kube_config.0.client_certificate)
        client_key             = base64decode(data.azurerm_kubernetes_cluster.this.kube_config.0.client_key)
        cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.this.kube_config.0.cluster_ca_certificate)
      }
    }
  EOF
}

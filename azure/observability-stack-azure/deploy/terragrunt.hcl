locals {
  repo_root = "${get_parent_terragrunt_dir()}/../../.."

  # List all storage accounts in the state resource group to find the one
  azure_suffix = run_cmd("--terragrunt-quiet", "az", "storage", "account", "list",
    "--resource-group", "terraform-states",
    "--query", "[0].name",
    "--output", "tsv"
  )
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_version = ">= 1.5"
      required_providers {
        azurerm = {
          source  = "hashicorp/azurerm"
          version = "~> 4.0"
        }
        helm = {
          source  = "hashicorp/helm"
          version = "~> 3.0"
        }
        kubernetes = {
          source  = "hashicorp/kubernetes"
          version = "~> 2.0"
        }
        local = {
          source  = "hashicorp/local"
          version = "~> 2.5"
        }
      }
    }

    provider "azurerm" {
      features {
        resource_group {
          prevent_deletion_if_contains_resources = false
        }
      }
    }

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

remote_state {
  backend = "azurerm"
  config = {
    resource_group_name  = "terraform-states"
    storage_account_name = local.azure_suffix
    container_name       = "terraform-state"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

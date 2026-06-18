# Dev environment — Observability Stack on Azure
# Pattern: aws/eks_rds/environments/dev/main.tf

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
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

data "azurerm_client_config" "current" {}

locals {
  environment = "dev"
  location    = "eastus2"

  common_tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Project     = "observability-stack-azure"
  }

  resource_group_name = "rg-observability"
  cluster_name        = "aks-observability"
}

# ═══════════════════════════════════════════
# 1. AKS + VNet
# ═══════════════════════════════════════════

module "aks" {
  source = "../../../../modules/aks"

  resource_group_name = local.resource_group_name
  location            = local.location
  cluster_name        = local.cluster_name
  kubernetes_version  = "1.34"
  node_count          = 2
  node_size           = "Standard_D2s_v3"
  os_disk_size_gb     = 60

  vnet_name            = "vnet-observability"
  vnet_address_space   = ["10.0.0.0/16"]
  aks_subnet_name      = "snet-aks"
  aks_subnet_prefixes  = ["10.0.1.0/24"]

  allowed_api_source_ips = []

  tags = local.common_tags
}

# ═══════════════════════════════════════════
# 2. PostgreSQL (disabled - eastus2 region
#    does not support PostgreSQL in this subscription)
# ═══════════════════════════════════════════


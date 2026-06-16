# Dev environment — Observability Stack on Azure
# Padrão: aws/eks_rds/environments/dev/main.tf
# Sobe apenas infraestrutura Azure (AKS + PostgreSQL)
# Monitoring (Helm/K8s) usa terragrunt separado

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

  backend "azurerm" {
    resource_group_name  = "terraform-states"
    storage_account_name = "tfstateqyppc0vt"
    container_name       = "terraform-state"
    key                  = "dev/terraform.tfstate"
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
  postgres_server     = "psql-observability"
}

# ═══════════════════════════════════════════
# 1. AKS + VNet
# ═══════════════════════════════════════════

module "aks" {
  source = "../../../modules/aks"

  resource_group_name = local.resource_group_name
  location            = local.location
  cluster_name        = local.cluster_name
  kubernetes_version  = "1.30"
  node_count          = 2
  node_size           = "Standard_B2s"
  os_disk_size_gb     = 60

  vnet_name            = "vnet-observability"
  vnet_address_space   = ["10.0.0.0/16"]
  aks_subnet_name      = "snet-aks"
  aks_subnet_prefixes  = ["10.0.1.0/24"]
  postgresql_subnet_name     = "snet-postgresql"
  postgresql_subnet_prefixes = ["10.0.2.0/24"]
  pe_subnet_name             = "snet-private-endpoints"
  pe_subnet_prefixes         = ["10.0.3.0/24"]

  allowed_api_source_ips = []

  tags = local.common_tags
}

# ═══════════════════════════════════════════
# 2. PostgreSQL
# ═══════════════════════════════════════════

resource "random_password" "db_password" {
  length  = 20
  special = false
}

module "postgresql" {
  source = "../../../modules/postgresql"

  resource_group_name = local.resource_group_name
  location            = local.location
  server_name         = local.postgres_server
  admin_user          = "psqladmin"
  admin_password      = random_password.db_password.result
  database_name       = "observability"
  postgres_version    = "16"
  sku_name            = "B_Standard_B1ms"
  storage_mb          = 32768
  subnet_name         = module.aks.postgresql_subnet_name
  vnet_name           = module.aks.vnet_name
  ha_enabled          = false

  tags = local.common_tags
}

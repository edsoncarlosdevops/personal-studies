# Bootstrap: Cria o backend Azure Storage para remote state
# Aplica primeiro: `terraform apply`
# Depois os ambientes usam este backend automaticamente

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
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

locals {
  storage_account_name = "${var.storage_account_prefix}${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_resource_group" "state" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Name      = "Terraform State"
    ManagedBy = "terraform"
  }
}

resource "azurerm_storage_account" "state" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.state.name
  location                 = azurerm_resource_group.state.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public = false

  tags = {
    Name      = "Terraform State"
    ManagedBy = "terraform"
  }
}

resource "azurerm_storage_container" "state" {
  storage_account_id  = azurerm_storage_account.state.id
  name                  = var.container_name
  container_access_type = "private"
}

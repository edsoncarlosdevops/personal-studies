terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                         = var.server_name
  resource_group_name          = var.resource_group_name
  location                     = "eastus2"
  version                      = var.postgres_version
  delegated_subnet_id          = var.subnet_id
  private_dns_zone_id          = azurerm_private_dns_zone.this.id
  administrator_login          = var.admin_user
  administrator_password       = var.admin_password
  storage_mb                   = var.storage_mb
  sku_name                     = var.sku_name
  zone                         = "1"

  dynamic "high_availability" {
    for_each = var.ha_enabled ? [1] : []
    content {
      mode = "ZoneRedundant"
    }
  }

  public_network_access_enabled = false
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup

  tags = var.tags
}

resource "azurerm_private_dns_zone" "this" {
  name                = "${var.server_name}.private.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = "${var.server_name}-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.this.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

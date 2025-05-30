resource "azurerm_resource_group" "appgrp" {
  name     = local.virtual_network.name
  location = local.resource_location
}

resource "azurerm_virtual_network" "example" {
  name                = local.virtual_network.name
  location            = local.resource_location
  resource_group_name = azurerm_resource_group.appgrp.name
  address_space       = local.virtual_network.address_prefixes

  subnet {
    name             = "subnet1"
    address_prefixes = [local.virtual_network.subnet_address_prefix[0]]
  }

  subnet {
    name             = "subnet2"
    address_prefixes = [local.virtual_network.subnet_address_prefix[1]]
  }

}

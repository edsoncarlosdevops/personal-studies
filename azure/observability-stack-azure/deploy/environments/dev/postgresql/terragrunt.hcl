terraform {
  source = "../../../modules/postgresql"
}

include {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../aks"]
}

dependency "aks" {
  config_path = "../aks"
}

inputs = {
  resource_group_name = dependency.aks.outputs.resource_group_name
  server_name         = "psql-observability"
  database_name       = "observability"
  postgres_version    = "16"
  admin_user          = "pgadmin"
  admin_password      = "P@ssw0rd1234!"
  sku_name            = "B_Standard_B1ms"
  storage_mb          = 32768
  subnet_name         = dependency.aks.outputs.postgresql_subnet_name
  vnet_name           = dependency.aks.outputs.vnet_name
  ha_enabled          = false
  tags                = dependency.aks.outputs.tags
}

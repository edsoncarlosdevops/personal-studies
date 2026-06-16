terraform {
  source = "/Users/edsoncarlos/Downloads/personal-studies/azure/observability-stack-azure/modules/aks"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  resource_group_name = "rg-observability"
  location            = "eastus2"
  cluster_name        = "aks-observability"
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

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Project     = "observability-stack-azure"
  }
}

terraform {
  source = "../../../../../monitoring/modules/monitoring/cert-manager"
}

include {
  path = find_in_parent_folders()
}

# Depende do namespace ser criado primeiro
dependencies {
  paths = ["../namespace"]
}

dependency "namespace" {
  config_path = "../namespace"
}

inputs = {
  cert_manager_release_name   = "cert-manager"
  cert_manager_chart_name     = "cert-manager"
  cert_manager_namespace      = "cert-manager"
  cert_manager_chart_version  = "v1.16.0"
  cert_manager_repository_url = "https://charts.jetstack.io"
}


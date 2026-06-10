terraform {
  source = "../../../../../monitoring/modules/monitoring/cert-manager"
}

include {
  path = find_in_parent_folders("root.hcl")
}

# Depende do namespace ser criado primeiro
dependencies {
  paths = ["../namespace"]
}

dependency "namespace" {
  mock_outputs = {
    namespace_name = "monitoring"
  }
  config_path = "../namespace"
}

inputs = {
  cert_manager_release_name   = "cert-manager"
  cert_manager_chart_name     = "cert-manager"
  cert_manager_namespace      = "cert-manager"
  cert_manager_chart_version  = "v1.16.0"
  cert_manager_repository_url = "https://charts.jetstack.io"
}


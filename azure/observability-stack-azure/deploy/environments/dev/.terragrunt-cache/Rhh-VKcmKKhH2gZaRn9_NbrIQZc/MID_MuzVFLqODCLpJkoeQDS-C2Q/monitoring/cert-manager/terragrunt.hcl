terraform {
  source = "../../../../../monitoring/modules/monitoring/cert-manager"
}

include {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../../aks"]
}

dependency "aks" {
  config_path = "../../aks"
}

inputs = {
  cert_manager_release_name   = "cert-manager"
  cert_manager_chart_name     = "cert-manager"
  cert_manager_namespace      = "cert-manager"
  cert_manager_chart_version  = "1.16.0"
  cert_manager_repository_url = "https://charts.jetstack.io"
}

terraform {
  source = "../../../../../monitoring/modules/monitoring/cert-manager"
}

include "root" {
  path = find_in_parent_folders()
}

include "monitoring" {
  path = "${get_terragrunt_dir()}/../terragrunt.hcl"
}





inputs = {
  cert_manager_release_name   = "cert-manager"
  cert_manager_chart_name     = "cert-manager"
  cert_manager_namespace      = "cert-manager"
  cert_manager_chart_version  = "1.16.0"
  cert_manager_repository_url = "https://charts.jetstack.io"
}

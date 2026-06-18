terraform {
  source = "../../../../../../../monitoring/modules/monitoring/tempo"
}

include "root" {
  path = find_in_parent_folders()
}

include "monitoring" {
  path = "${get_terragrunt_dir()}/../root.hcl"
}





inputs = {
  tempo_release_name   = "tempo"
  tempo_chart_name     = "tempo"
  tempo_namespace      = "monitoring"
  tempo_chart_version  = "1.7.1"
  tempo_repository_url = "https://grafana.github.io/helm-charts"
}

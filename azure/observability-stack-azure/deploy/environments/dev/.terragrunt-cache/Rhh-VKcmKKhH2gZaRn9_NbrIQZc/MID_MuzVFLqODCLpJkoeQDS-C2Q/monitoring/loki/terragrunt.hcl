terraform {
  source = "../../../../../monitoring/modules/monitoring/loki"
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
  loki_release_name   = "loki"
  loki_chart_name     = "loki"
  loki_namespace      = "monitoring"
  loki_chart_version  = "5.41.0"
  loki_repository_url = "https://grafana.github.io/helm-charts"
}

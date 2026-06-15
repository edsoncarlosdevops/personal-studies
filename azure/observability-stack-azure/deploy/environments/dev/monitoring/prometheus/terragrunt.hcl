terraform {
  source = "../../../../../monitoring/modules/monitoring/prometheus"
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
  context                   = "aks-dev"
  prometheus_release_name   = "prometheus"
  prometheus_chart_name     = "prometheus"
  prometheus_namespace      = "monitoring"
  prometheus_chart_version  = "27.1.0"
  prometheus_repository_url = "https://prometheus-community.github.io/helm-charts"
  prometheus_vs_name        = "ignore"
  prometheus_vs_dns         = "localhost"
  prometheus_vs_port        = 80
  prometheus_replica_count  = 1
}

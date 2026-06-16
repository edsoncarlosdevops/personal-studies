terraform {
  source = "../../../../../monitoring/modules/monitoring/grafana"
}

include {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../../aks", "../prometheus", "../loki", "../tempo"]
}

dependency "aks" {
  config_path = "../../aks"
}

dependency "prometheus" {
  config_path = "../prometheus"
}

dependency "loki" {
  config_path = "../loki"
}

dependency "tempo" {
  config_path = "../tempo"
}

inputs = {
  context                = "aks-dev"
  grafana_release_name   = "grafana"
  grafana_chart_name     = "grafana"
  grafana_namespace      = "monitoring"
  grafana_chart_version  = "9.3.2"
  grafana_repository_url = "https://grafana.github.io/helm-charts"
  grafana_vs_name        = "ignore"
  grafana_vs_dns         = "localhost"
  grafana_vs_port        = 80
  grafana_replica_count  = 1
}

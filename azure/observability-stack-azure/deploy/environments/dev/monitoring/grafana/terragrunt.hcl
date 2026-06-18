terraform {
  source = "../../../../../../../monitoring/modules/monitoring/grafana"
}

include "root" {
  path = find_in_parent_folders()
}

include "monitoring" {
  path = "${get_terragrunt_dir()}/../root.hcl"
}





dependency "prometheus" {
  config_path = "../prometheus"
  mock_outputs = {
    prometheus_url_internal = "http://prometheus-server.monitoring.svc.cluster.local:80"
    prometheus_service_name = "prometheus-server"
    prometheus_namespace    = "monitoring"
  }
}

dependency "loki" {
  config_path = "../loki"
  mock_outputs = {
    loki_url_internal = "http://loki.monitoring.svc.cluster.local:3100"
    loki_service_name = "loki"
    loki_namespace    = "monitoring"
  }
}

dependency "tempo" {
  config_path = "../tempo"
  mock_outputs = {
    # tempo has no outputs, mock needed to prevent dependency errors
    tempo_service_name = "tempo"
    tempo_namespace    = "monitoring"
  }
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


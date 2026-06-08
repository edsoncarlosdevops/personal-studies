terraform {
  source = "../../../../modules/monitoring/grafana"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  grafana_release_name   = "grafana"
  grafana_chart_name     = "grafana"
  grafana_namespace      = "monitoring"
  grafana_chart_version  = "9.3.2"
  grafana_repository_url = "https://grafana.github.io/helm-charts"

  grafana_vs_name = "ignore"
  grafana_vs_dns  = "localhost"
  grafana_vs_port = 80

  grafana_replica_count = 1
}

terraform {
  source = "../../../modules/monitoring/loki"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  loki_release_name   = "loki-local"
  loki_chart_name     = "loki"
  loki_namespace      = "monitoring"
  loki_chart_version  = "5.41.0" # Versão estável recente
  loki_repository_url = "https://grafana.github.io/helm-charts"
}
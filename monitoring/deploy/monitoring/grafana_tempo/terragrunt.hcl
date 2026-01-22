terraform {
  source = "../../../modules/monitoring/grafana_tempo"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  tempo_release_name   = "tempo-local"
  tempo_chart_name     = "tempo"
  tempo_namespace      = "monitoring"
  tempo_chart_version  = "1.7.1"
  tempo_repository_url = "https://grafana.github.io/helm-charts"
}
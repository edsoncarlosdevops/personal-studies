terraform {
  source = "../../../../../monitoring/modules/observability/loki"
}

include {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  loki_release_name   = "loki"
  loki_chart_name     = "loki"
  loki_namespace      = "monitoring"
  loki_chart_version  = "6.28.0"
  loki_repository_url = "https://grafana.github.io/helm-charts"
}


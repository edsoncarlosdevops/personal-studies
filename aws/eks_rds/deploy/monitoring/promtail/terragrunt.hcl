terraform {
  source = "../../../../../monitoring/modules/monitoring/promtail"
}

include {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  promtail_release_name    = "promtail"
  promtail_chart_name      = "promtail"
  promtail_namespace       = "monitoring"
  promtail_chart_version   = "6.16.6"
  promtail_repository_url  = "https://grafana.github.io/helm-charts"
  promtail_loki_endpoint   = "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
}

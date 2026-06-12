terraform {
  source = "../../../../../monitoring/modules/monitoring/opentelemetry-operator"
}

include {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  otel_operator_release_name   = "opentelemetry-operator"
  otel_operator_chart_name     = "opentelemetry-operator"
  otel_operator_namespace      = "monitoring"
  otel_operator_chart_version  = "0.105.0"
  otel_operator_repository_url = "https://open-telemetry.github.io/opentelemetry-helm-charts"
}

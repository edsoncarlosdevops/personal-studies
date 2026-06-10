terraform {
  source = "../../../../../monitoring/modules/monitoring/opentelemetry-operator"
}

include {
  path = find_in_parent_folders("root.hcl")
}

# Depende do namespace ser criado primeiro
dependencies {
  paths = ["../namespace"]
}

dependency "namespace" {
  mock_outputs = {
    namespace_name = "monitoring"
  }
  config_path = "../namespace"
}

inputs = {
  otel_operator_release_name   = "opentelemetry-operator"
  otel_operator_chart_name     = "opentelemetry-operator"
  otel_operator_namespace      = "monitoring"
  otel_operator_chart_version  = "0.105.0"
  otel_operator_repository_url = "https://open-telemetry.github.io/opentelemetry-helm-charts"
}


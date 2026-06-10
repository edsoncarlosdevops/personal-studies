terraform {
  source = "../../../../../monitoring/modules/monitoring/opentelemetry-collector"
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
  otel_collector_release_name   = "opentelemetry-collector"
  otel_collector_chart_name     = "opentelemetry-collector"
  otel_collector_namespace      = "monitoring"
  otel_collector_chart_version  = "0.105.0"
  otel_collector_repository_url = "https://open-telemetry.github.io/opentelemetry-helm-charts"
}


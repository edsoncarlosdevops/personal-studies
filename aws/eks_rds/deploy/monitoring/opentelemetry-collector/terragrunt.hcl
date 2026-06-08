terraform {
  source = "../../../../../monitoring/modules/monitoring/opentelemetry-collector"
}

include {
  path = find_in_parent_folders()
}

# Depende do namespace ser criado primeiro
dependencies {
  paths = ["../namespace"]
}

dependency "namespace" {
  config_path = "../namespace"
}

inputs = {
  opentelemetry_collector_release_name   = "opentelemetry-collector"
  opentelemetry_collector_chart_name     = "opentelemetry-collector"
  opentelemetry_collector_namespace      = "monitoring"
  opentelemetry_collector_chart_version  = "0.105.0"
  opentelemetry_collector_repository_url = "https://open-telemetry.github.io/opentelemetry-helm-charts"
}
  opentelemetry_collector_namespace      = "monitoring"
  opentelemetry_collector_chart_version  = "0.105.0"
  opentelemetry_collector_repository_url = "https://open-telemetry.github.io/opentelemetry-helm-charts"
}


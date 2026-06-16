terraform {
  source = "../../../../../monitoring/modules/monitoring/opentelemetry-collector"
}

include {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../../aks", "../tempo"]
}

dependency "aks" {
  config_path = "../../aks"
}

dependency "tempo" {
  config_path = "../tempo"
}

inputs = {
  otel_collector_release_name   = "opentelemetry-collector"
  otel_collector_chart_name     = "opentelemetry-collector"
  otel_collector_namespace      = "monitoring"
  otel_collector_chart_version  = "0.105.0"
  otel_collector_repository_url = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  otel_collector_replica_count  = 1
}

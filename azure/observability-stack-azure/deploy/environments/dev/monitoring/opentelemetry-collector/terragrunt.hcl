terraform {
  source = "../../../../../../../monitoring/modules/opentelemetry-collector"
}

include "root" {
  path = find_in_parent_folders()
}

include "monitoring" {
  path = "${get_terragrunt_dir()}/../root.hcl"
}





dependency "tempo" {
  config_path = "../tempo"
  mock_outputs = {
    tempo_service_name = "tempo"
    tempo_namespace    = "monitoring"
  }
}

inputs = {
  otel_collector_release_name   = "opentelemetry-collector"
  otel_collector_chart_name     = "opentelemetry-collector"
  otel_collector_namespace      = "monitoring"
  otel_collector_chart_version  = "0.105.0"
  otel_collector_repository_url = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  otel_collector_replica_count  = 1
}


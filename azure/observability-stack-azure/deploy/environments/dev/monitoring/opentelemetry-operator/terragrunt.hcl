terraform {
  source = "../../../../../../../monitoring/modules/monitoring/opentelemetry-operator"
}

include "root" {
  path = find_in_parent_folders()
}

include "monitoring" {
  path = "${get_terragrunt_dir()}/../root.hcl"
}





dependency "cert-manager" {
  config_path = "../cert-manager"
  mock_outputs = {
    cert_manager_service_name = "cert-manager"
    cert_manager_namespace    = "cert-manager"
  }
}

inputs = {
  otel_operator_release_name   = "opentelemetry-operator"
  otel_operator_chart_name     = "opentelemetry-operator"
  otel_operator_namespace      = "monitoring"
  otel_operator_chart_version  = "0.105.0"
  otel_operator_repository_url = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  otel_operator_replica_count  = 1
}


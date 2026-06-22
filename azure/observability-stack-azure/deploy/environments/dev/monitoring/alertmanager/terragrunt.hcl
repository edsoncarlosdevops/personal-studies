terraform {
  source = "../../../../../../../monitoring/modules/observability/alertmanager"
}

include "root" {
  path = find_in_parent_folders()
}

include "monitoring" {
  path = "${get_terragrunt_dir()}/../root.hcl"
}





dependency "prometheus" {
  config_path = "../prometheus"
  mock_outputs = {
    prometheus_url_internal = "http://prometheus-server.monitoring.svc.cluster.local:80"
    prometheus_service_name = "prometheus-server"
    prometheus_namespace    = "monitoring"
  }
}

inputs = {
  alertmanager_release_name   = "alertmanager"
  alertmanager_chart_name     = "alertmanager"
  alertmanager_namespace      = "monitoring"
  alertmanager_chart_version  = "1.8.0"
  alertmanager_repository_url = "https://prometheus-community.github.io/helm-charts"
}


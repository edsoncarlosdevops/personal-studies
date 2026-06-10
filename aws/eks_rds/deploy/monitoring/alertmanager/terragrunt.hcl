terraform {
  source = "../../../../../monitoring/modules/monitoring/alertmanager"
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
  alertmanager_release_name   = "alertmanager"
  alertmanager_chart_name     = "alertmanager"
  alertmanager_namespace      = "monitoring"
  alertmanager_chart_version  = "1.8.0"
  alertmanager_repository_url = "https://prometheus-community.github.io/helm-charts"
}

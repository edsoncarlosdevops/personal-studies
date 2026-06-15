terraform {
  source = "../../../../../monitoring/modules/monitoring/alertmanager"
}

include {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../../aks", "../prometheus"]
}

dependency "aks" {
  config_path = "../../aks"
}

dependency "prometheus" {
  config_path = "../prometheus"
}

inputs = {
  alertmanager_release_name   = "alertmanager"
  alertmanager_chart_name     = "alertmanager"
  alertmanager_namespace      = "monitoring"
  alertmanager_chart_version  = "1.8.0"
  alertmanager_repository_url = "https://prometheus-community.github.io/helm-charts"
}

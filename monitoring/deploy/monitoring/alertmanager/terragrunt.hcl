terraform {
  source = "../../../modules/monitoring/alertmanager"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  alertmanager_release_name   = "alertmanager-local"
  alertmanager_chart_name     = "alertmanager"
  alertmanager_namespace      = "monitoring"
  alertmanager_chart_version  = "1.8.0" # Verifique a versão compatível no artifacthub
  alertmanager_repository_url = "https://prometheus-community.github.io/helm-charts"
}
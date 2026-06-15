terraform {
  source = "../../../../../monitoring/modules/monitoring/opencost"
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
  opencost_release_name          = "opencost"
  opencost_chart_name            = "opencost"
  opencost_namespace             = "monitoring"
  opencost_chart_version         = "2.2.0"
  opencost_repository_url        = "https://opencost.github.io/opencost-helm-chart"
  opencost_prometheus_address    = "http://prometheus-server.monitoring.svc.cluster.local"
  opencost_cluster_id            = "aks-observability"
  opencost_resources_preset      = "small"
  opencost_replica_count         = 1
}

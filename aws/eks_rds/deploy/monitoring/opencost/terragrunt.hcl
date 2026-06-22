terraform {
  source = "../../../../../monitoring/modules/observability/opencost"
}

include {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  opencost_release_name          = "opencost"
  opencost_chart_name            = "opencost"
  opencost_namespace             = "monitoring"
  opencost_chart_version         = "2.2.0"
  opencost_repository_url        = "https://opencost.github.io/opencost-helm-chart"
  opencost_prometheus_address    = "http://prometheus-server.monitoring.svc.cluster.local:80"
  opencost_cluster_id            = "eks-dev-cluster"
  opencost_resources_preset      = "small"
}


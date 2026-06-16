# Common locals shared across all Terragrunt modules
# Used via: include > path = find_in_parent_folders()

locals {
  environment = "dev"
  location    = "eastus2"

  common_tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Project     = "observability-stack-azure"
  }

  # Helm repositories
  helm_repos = {
    prometheus   = "https://prometheus-community.github.io/helm-charts"
    grafana      = "https://grafana.github.io/helm-charts"
    jetstack     = "https://charts.jetstack.io"
    opencost     = "https://opencost.github.io/opencost-helm-chart"
    opentelemetry = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  }

  # Monitoring namespace
  monitoring_namespace = "monitoring"

  # Resource names
  resource_group_name = "rg-observability"
  cluster_name        = "aks-observability"
  postgres_server     = "psql-observability"
}

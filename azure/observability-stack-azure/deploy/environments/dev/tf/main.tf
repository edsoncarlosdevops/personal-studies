# ═══════════════════════════════════════════
# Dev environment - Observability Stack on Azure
# Similar ao padrão: aws/eks_rds/environments/dev/main.tf
# ═══════════════════════════════════════════

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

  backend "azurerm" {
    resource_group_name  = "terraform-states"
    storage_account_name = "tfstateqyppc0vt"
    container_name       = "terraform-state"
    key                  = "dev/terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_client_config" "current" {}

# ── Locals ──
locals {
  environment = "dev"
  location    = "eastus2"

  common_tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Project     = "observability-stack-azure"
  }

  resource_group_name = "rg-observability"
  cluster_name        = "aks-observability"
  postgres_server     = "psql-observability"
  monitoring_ns       = "monitoring"
}

# ═══════════════════════════════════════════
# 1. AKS + VNet
# ═══════════════════════════════════════════

module "aks" {
  source = "../../../modules/aks"

  resource_group_name = local.resource_group_name
  location            = local.location
  cluster_name        = local.cluster_name
  kubernetes_version  = "1.30"
  node_count          = 2
  node_size           = "Standard_B2s"
  os_disk_size_gb     = 60

  vnet_name            = "vnet-observability"
  vnet_address_space   = ["10.0.0.0/16"]
  aks_subnet_name      = "snet-aks"
  aks_subnet_prefixes  = ["10.0.1.0/24"]
  postgresql_subnet_name     = "snet-postgresql"
  postgresql_subnet_prefixes = ["10.0.2.0/24"]
  pe_subnet_name             = "snet-private-endpoints"
  pe_subnet_prefixes         = ["10.0.3.0/24"]

  allowed_api_source_ips = []

  tags = local.common_tags
}

# ═══════════════════════════════════════════
# 2. PostgreSQL (com senha aleatória)
# ═══════════════════════════════════════════

resource "random_password" "db_password" {
  length  = 20
  special = false
}

module "postgresql" {
  source = "../../../modules/postgresql"

  resource_group_name = local.resource_group_name
  location            = local.location
  server_name         = local.postgres_server
  admin_user          = "psqladmin"
  admin_password      = random_password.db_password.result
  database_name       = "observability"
  postgres_version    = "16"
  sku_name            = "B_Standard_B1ms"
  storage_mb          = 32768
  subnet_name         = module.aks.postgresql_subnet_name
  vnet_name           = module.aks.vnet_name
  ha_enabled          = false

  tags = local.common_tags
}

# ═══════════════════════════════════════════
# 3. K8s + Helm providers (após AKS criado)
# ═══════════════════════════════════════════

provider "kubernetes" {
  host                   = module.aks.kube_config[0].host
  client_certificate     = base64decode(module.aks.kube_config[0].client_certificate)
  client_key             = base64decode(module.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.aks.kube_config[0].host
    client_certificate     = base64decode(module.aks.kube_config[0].client_certificate)
    client_key             = base64decode(module.aks.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config[0].cluster_ca_certificate)
  }
}

# ═══════════════════════════════════════════
# 4. Monitoring (Helm charts)
# ═══════════════════════════════════════════

module "cert_manager" {
  source = "../../../../monitoring/modules/monitoring/cert-manager"

  cert_manager_release_name   = "cert-manager"
  cert_manager_chart_name     = "cert-manager"
  cert_manager_namespace      = "cert-manager"
  cert_manager_chart_version  = "1.17.1"
  cert_manager_repository_url = "https://charts.jetstack.io"
  cert_manager_replica_count  = 1
}

module "prometheus" {
  source = "../../../../monitoring/modules/monitoring/prometheus"

  prometheus_release_name   = "prometheus"
  prometheus_chart_name     = "prometheus"
  prometheus_namespace      = local.monitoring_ns
  prometheus_chart_version  = "27.1.0"
  prometheus_repository_url = "https://prometheus-community.github.io/helm-charts"
  prometheus_replica_count  = 1
}

module "alertmanager" {
  source = "../../../../monitoring/modules/monitoring/alertmanager"

  alertmanager_release_name   = "alertmanager"
  alertmanager_chart_name     = "alertmanager"
  alertmanager_namespace      = local.monitoring_ns
  alertmanager_chart_version  = "1.14.0"
  alertmanager_repository_url = "https://prometheus-community.github.io/helm-charts"
  alertmanager_replica_count  = 1
}

module "loki" {
  source = "../../../../monitoring/modules/monitoring/loki"

  loki_release_name   = "loki"
  loki_chart_name     = "loki"
  loki_namespace      = local.monitoring_ns
  loki_chart_version  = "6.28.0"
  loki_repository_url = "https://grafana.github.io/helm-charts"
  loki_replica_count  = 1
}

module "promtail" {
  source = "../../../../monitoring/modules/monitoring/promtail"

  promtail_release_name   = "promtail"
  promtail_chart_name     = "promtail"
  promtail_namespace      = local.monitoring_ns
  promtail_chart_version  = "6.16.6"
  promtail_repository_url = "https://grafana.github.io/helm-charts"
  promtail_replica_count  = 1
}

module "tempo" {
  source = "../../../../monitoring/modules/monitoring/tempo"

  tempo_release_name   = "tempo"
  tempo_chart_name     = "tempo"
  tempo_namespace      = local.monitoring_ns
  tempo_chart_version  = "1.18.0"
  tempo_repository_url = "https://grafana.github.io/helm-charts"
  tempo_replica_count  = 1
}

module "grafana" {
  source = "../../../../monitoring/modules/monitoring/grafana"

  grafana_release_name   = "grafana"
  grafana_chart_name     = "grafana"
  grafana_namespace      = local.monitoring_ns
  grafana_chart_version  = "9.3.2"
  grafana_repository_url = "https://grafana.github.io/helm-charts"
  grafana_replica_count  = 1
}

module "opentelemetry_operator" {
  source = "../../../../monitoring/modules/monitoring/opentelemetry-operator"

  otel_operator_release_name   = "opentelemetry-operator"
  otel_operator_chart_name     = "opentelemetry-operator"
  otel_operator_namespace      = local.monitoring_ns
  otel_operator_chart_version  = "0.84.0"
  otel_operator_repository_url = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  otel_operator_replica_count  = 1
}

module "opentelemetry_collector" {
  source = "../../../../monitoring/modules/monitoring/opentelemetry-collector"

  otel_collector_release_name   = "opentelemetry-collector"
  otel_collector_chart_name     = "opentelemetry-collector"
  otel_collector_namespace      = local.monitoring_ns
  otel_collector_chart_version  = "0.120.0"
  otel_collector_repository_url = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  otel_collector_replica_count  = 1
}

module "opencost" {
  source = "../../../../monitoring/modules/monitoring/opencost"

  opencost_release_name   = "opencost"
  opencost_chart_name     = "opencost"
  opencost_namespace      = local.monitoring_ns
  opencost_chart_version  = "1.45.0"
  opencost_repository_url = "https://opencost.github.io/opencost-helm-charts"
  opencost_replica_count  = 1
}

module "postgres_exporter" {
  source = "../../../../monitoring/modules/monitoring/postgres-exporter"

  postgres_exporter_release_name   = "postgres-exporter"
  postgres_exporter_chart_name     = "prometheus-postgres-exporter"
  postgres_exporter_namespace      = local.monitoring_ns
  postgres_exporter_chart_version  = "6.6.0"
  postgres_exporter_repository_url = "https://prometheus-community.github.io/helm-charts"
  postgres_exporter_replica_count  = 1
  postgres_exporter_host           = module.postgresql.server_fqdn
  postgres_exporter_user           = "psqladmin"
  postgres_exporter_password       = random_password.db_password.result
  postgres_exporter_database       = "postgres"
  postgres_exporter_sslmode        = "require"
}

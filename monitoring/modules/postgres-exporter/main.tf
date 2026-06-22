resource "helm_release" "postgres_exporter" {
  name       = var.release_name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-postgres-exporter"
  version    = var.chart_version
  namespace  = var.namespace

  set {
    name  = "config.datasource.host"
    value = var.db_host
  }

  set {
    name  = "config.datasource.user"
    value = var.db_user
  }

  set {
    name  = "config.datasource.password"
    value = var.db_password
  }

  set {
    name  = "config.datasource.database"
    value = var.db_name
  }

  set {
    name  = "config.datasource.sslmode"
    value = "require"
  }

  set {
    name  = "serviceMonitor.enabled"
    value = "true"
  }

  set {
    name  = "serviceMonitor.namespace"
    value = var.namespace
  }

  set {
    name  = "resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "resources.requests.memory"
    value = "64Mi"
  }

  set {
    name  = "resources.limits.cpu"
    value = "100m"
  }

  set {
    name  = "resources.limits.memory"
    value = "128Mi"
  }
}

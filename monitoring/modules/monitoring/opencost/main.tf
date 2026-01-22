########
# Helm #
########

locals {
  # Mantive sua lógica de presets, pois é útil para controlar recursos localmente
  resource_presets = {
    small = {
      requests = { cpu = "50m", memory = "64Mi" }
      limits   = { cpu = "200m", memory = "256Mi" }
    }
    medium = {
      requests = { cpu = "100m", memory = "128Mi" }
      limits   = { cpu = "500m", memory = "512Mi" }
    }
  }

  opencost_resources = local.resource_presets[var.opencost_resources_preset]
}

resource "helm_release" "opencost" {
  name             = var.opencost_release_name
  chart            = var.opencost_chart_name
  create_namespace = true
  wait             = false
  namespace        = var.opencost_namespace
  version          = var.opencost_chart_version
  repository       = var.opencost_repository_url
  
  values = [
    templatefile("${path.module}/config/values.yaml", {
      opencost_prometheus_address = var.opencost_prometheus_address
      opencost_cluster_id         = var.opencost_cluster_id
      opencost_replica_count      = var.opencost_replica_count
      opencost_resources_config   = jsonencode(local.opencost_resources)
    })
  ]
}
########
# Helm #
########

resource "helm_release" "prometheus" {
  name             = var.prometheus_release_name
  chart            = var.prometheus_chart_name
  create_namespace = false
  wait             = true
  namespace        = var.prometheus_namespace
  version          = var.prometheus_chart_version
  repository       = var.prometheus_repository_url

  values = [
    templatefile("${path.module}/config/values.yaml", {
      prometheus_replica_count = var.prometheus_replica_count
    })
  ]
}
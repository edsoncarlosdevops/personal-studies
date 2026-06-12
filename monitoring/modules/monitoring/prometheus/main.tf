########
# Helm #
########

resource "helm_release" "prometheus" {
  name             = var.prometheus_release_name
  chart            = var.prometheus_chart_name
  create_namespace = true
  wait             = false
  timeout          = 600
  namespace        = var.prometheus_namespace
  version          = var.prometheus_chart_version
  repository       = var.prometheus_repository_url
  force_update     = true
  upgrade_install  = true
  atomic           = true
  cleanup_on_fail  = true

  values = [
    templatefile("${path.module}/config/values.yaml", {
      prometheus_replica_count = var.prometheus_replica_count
    })
  ]
}
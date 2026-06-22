########
# Helm #
########

resource "helm_release" "promtail" {
  name             = var.promtail_release_name
  chart            = var.promtail_chart_name
  create_namespace = true
  wait             = true
  namespace        = var.promtail_namespace
  version          = var.promtail_chart_version
  repository       = var.promtail_repository_url
  force_update     = true
  cleanup_on_fail  = true
  upgrade_install  = true

  values = [
    templatefile("${path.module}/config/values.yaml", {
      promtail_loki_endpoint = var.promtail_loki_endpoint
    })
  ]
}

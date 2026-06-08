resource "helm_release" "loki" {
  name             = var.loki_release_name
  chart            = var.loki_chart_name
  create_namespace = false
  wait             = false
  namespace        = var.loki_namespace
  version          = var.loki_chart_version
  repository       = var.loki_repository_url
  timeout          = 600
  force_update     = true
  cleanup_on_fail  = true

  values = [
    templatefile("${path.module}/config/values.yaml", {
      loki_pvc_size = "10Gi"
    })
  ]
}
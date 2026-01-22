resource "helm_release" "loki" {
  name             = var.loki_release_name
  chart            = var.loki_chart_name
  create_namespace = false
  wait             = false # Não trava o deploy esperando ficar ready
  namespace        = var.loki_namespace
  version          = var.loki_chart_version
  repository       = var.loki_repository_url

  values = [
    templatefile("${path.module}/config/values.yaml", {
      # Força SingleBinary localmente
      loki_pvc_size = "10Gi"
    })
  ]
}
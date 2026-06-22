resource "helm_release" "tempo" {
  name             = var.tempo_release_name
  chart            = var.tempo_chart_name
  repository       = var.tempo_repository_url
  namespace        = var.tempo_namespace
  version          = var.tempo_chart_version
  create_namespace = true
  wait             = false
  force_update     = true
  cleanup_on_fail  = true
  upgrade_install  = true

  values = [
    templatefile("${path.module}/config/values.yaml", {
      replica_count = 1
    })
  ]
}
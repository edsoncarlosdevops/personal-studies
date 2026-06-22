resource "helm_release" "alertmanager" {
  name             = var.alertmanager_release_name
  chart            = var.alertmanager_chart_name
  create_namespace = true
  wait             = true
  namespace        = var.alertmanager_namespace
  version          = var.alertmanager_chart_version
  repository       = var.alertmanager_repository_url
  force_update     = true
  cleanup_on_fail  = true
  upgrade_install  = true
  
  values = [
    file("${path.module}/config/values.yaml")
  ]
}
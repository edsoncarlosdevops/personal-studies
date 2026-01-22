resource "helm_release" "alertmanager" {
  name             = var.alertmanager_release_name
  chart            = var.alertmanager_chart_name
  create_namespace = false
  wait             = true
  namespace        = var.alertmanager_namespace
  version          = var.alertmanager_chart_version
  repository       = var.alertmanager_repository_url
  
  values = [
    file("${path.module}/config/values.yaml")
  ]
}
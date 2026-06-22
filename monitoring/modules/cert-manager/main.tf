########
# Helm #
########

resource "helm_release" "cert_manager" {
  name             = var.cert_manager_release_name
  chart            = var.cert_manager_chart_name
  create_namespace = true
  wait             = true
  namespace        = var.cert_manager_namespace
  version          = var.cert_manager_chart_version
  repository       = var.cert_manager_repository_url
  force_update     = true
  cleanup_on_fail  = true
  upgrade_install  = true

  values = [
    yamlencode({
      crds = {
        enabled = true
      }
    })
  ]
}


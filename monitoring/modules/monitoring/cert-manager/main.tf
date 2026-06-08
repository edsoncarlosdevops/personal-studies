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

  values = [
    yamlencode({
      crds = {
        enabled = true
      }
    })
  ]
}


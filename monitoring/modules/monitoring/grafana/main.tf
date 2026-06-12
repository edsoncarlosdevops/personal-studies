########
# Helm #
########

resource "helm_release" "grafana" {
  name             = var.grafana_release_name
  chart            = var.grafana_chart_name
  create_namespace = true
  wait             = true
  namespace        = var.grafana_namespace
  version          = var.grafana_chart_version
  repository       = var.grafana_repository_url
  force_update     = true
  cleanup_on_fail  = true
  upgrade_install  = true
  values           = [data.template_file.values.rendered]
}

data "template_file" "values" {
  template = file("${path.module}/config/values.yaml")
  vars = {
    grafana_replica_count = var.grafana_replica_count
  }
}


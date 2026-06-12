########
# Helm #
########

resource "helm_release" "opentelemetry_collector" {
  name             = var.otel_collector_release_name
  chart            = var.otel_collector_chart_name
  create_namespace = true
  wait             = true
  namespace        = var.otel_collector_namespace
  version          = var.otel_collector_chart_version
  repository       = var.otel_collector_repository_url
  force_update     = true
  cleanup_on_fail  = true
  upgrade_install  = true

  values = [
    templatefile("${path.module}/config/values.yaml", {
      otel_collector_replica_count = var.otel_collector_replica_count
    })
  ]
}


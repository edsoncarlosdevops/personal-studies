########
# Helm #
########

resource "helm_release" "opentelemetry_operator" {
  name             = var.otel_operator_release_name
  chart            = var.otel_operator_chart_name
  create_namespace = true
  wait             = true
  namespace        = var.otel_operator_namespace
  version          = var.otel_operator_chart_version
  repository       = var.otel_operator_repository_url
  force_update     = true
  cleanup_on_fail  = true
  upgrade_install  = true

  values = [
    templatefile("${path.module}/config/values.yaml", {
      otel_operator_replica_count = var.otel_operator_replica_count
    })
  ]
}

########
# Helm #
########

resource "helm_release" "thanos" {
  name             = var.thanos_release_name
  chart            = var.thanos_chart_name
  create_namespace = true
  wait             = false
  timeout          = 600
  namespace        = var.thanos_namespace
  version          = var.thanos_chart_version
  repository       = var.thanos_repository_url
  force_update     = true
  upgrade_install  = true
  atomic           = true
  cleanup_on_fail  = true

  values = [
    templatefile("${path.module}/config/values.yaml", {
      thanos_store_enabled     = var.thanos_store_enabled
      thanos_compactor_enabled = var.thanos_compactor_enabled
      thanos_query_enabled     = var.thanos_query_enabled
      thanos_query_replicas    = var.thanos_query_replicas
      thanos_objstore_type     = var.thanos_objstore_type
      thanos_objstore_bucket   = var.thanos_objstore_bucket
      thanos_objstore_endpoint = var.thanos_objstore_endpoint
      thanos_retention_raw     = var.thanos_retention_raw
      thanos_retention_5m      = var.thanos_retention_5m
      thanos_retention_1h      = var.thanos_retention_1h
    })
  ]
}

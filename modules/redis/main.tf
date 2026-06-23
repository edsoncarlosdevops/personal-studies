########
# Helm #
########

resource "helm_release" "redis" {
  name             = var.redis_release_name
  chart            = var.redis_chart_name
  create_namespace = true
  wait             = false
  timeout          = 600
  namespace        = var.redis_namespace
  version          = var.redis_chart_version
  repository       = var.redis_repository_url
  force_update     = true
  upgrade_install  = true
  atomic           = true
  cleanup_on_fail  = true

  values = [
    templatefile("${path.module}/config/values.yaml", {
      redis_replica_count    = var.redis_replica_count
      redis_auth_enabled     = var.redis_auth_enabled
      redis_persistence_size = var.redis_persistence_size
      redis_architecture     = var.redis_architecture
    })
  ]
}

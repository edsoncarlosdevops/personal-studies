########
# Helm #
########

resource "helm_release" "keycloak" {
  name             = var.keycloak_release_name
  chart            = var.keycloak_chart_name
  create_namespace = true
  wait             = false
  timeout          = 600
  namespace        = var.keycloak_namespace
  version          = var.keycloak_chart_version
  repository       = var.keycloak_repository_url
  force_update     = true
  upgrade_install  = true
  atomic           = true
  cleanup_on_fail  = true

  values = [
    templatefile("${path.module}/config/values.yaml", {
      keycloak_replica_count       = var.keycloak_replica_count
      keycloak_admin_user          = var.keycloak_admin_user
      keycloak_admin_password      = var.keycloak_admin_password
      keycloak_postgresql_enabled  = var.keycloak_postgresql_enabled
      keycloak_postgresql_password = var.keycloak_postgresql_password
    })
  ]
}

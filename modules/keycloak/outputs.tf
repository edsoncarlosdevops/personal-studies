# ═══════════════════════════════════════════════════════════
# Keycloak - Outputs Uteis
# ═══════════════════════════════════════════════════════════

output "keycloak_url_internal" {
  value       = "http://keycloak.${var.keycloak_namespace}.svc.cluster.local:8080"
  description = "URL interna do Keycloak (usada por aplicacoes no cluster para autenticacao)"
}

output "keycloak_admin_console_url" {
  value       = "http://keycloak.${var.keycloak_namespace}.svc.cluster.local:8080/admin"
  description = "URL do console administrativo do Keycloak"
}

output "keycloak_port_forward_command" {
  value       = "kubectl -n ${var.keycloak_namespace} port-forward svc/keycloak 8080:8080"
  description = "Comando para expor o Keycloak localmente (http://localhost:8080/admin)"
}

output "keycloak_auth_endpoint_example" {
  value       = "http://keycloak.${var.keycloak_namespace}.svc.cluster.local:8080/realms/master/protocol/openid-connect/auth"
  description = "Endpoint de autenticacao OIDC do Keycloak (realm master)"
}

output "keycloak_health_check" {
  value       = "kubectl -n ${var.keycloak_namespace} exec deploy/keycloak -- curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/health"
  description = "Comando para verificar saude do Keycloak (deve retornar 200)"
}

output "keycloak_namespace" {
  value       = var.keycloak_namespace
  description = "Namespace onde o Keycloak esta instalado"
}

output "keycloak_admin_user" {
  value       = var.keycloak_admin_user
  description = "Usuario administrador do Keycloak"
}

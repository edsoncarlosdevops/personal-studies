# ═══════════════════════════════════════════════════════════
# Redis - Outputs Uteis
# ═══════════════════════════════════════════════════════════

output "redis_url_internal" {
  value       = "redis-master.${var.redis_namespace}.svc.cluster.local:6379"
  description = "URL interna do Redis Master (usada por aplicacoes no cluster)"
}

output "redis_replicas_url_internal" {
  value       = "redis-replicas.${var.redis_namespace}.svc.cluster.local:6379"
  description = "URL interna das Replicas Redis (usada para leitura distribuida)"
}

output "redis_get_password_command" {
  value       = "kubectl get secret --namespace ${var.redis_namespace} redis -o jsonpath=\"{.data.redis-password}\" | base64 --decode"
  description = "Comando para obter a senha do Redis"
}

output "redis_port_forward_command" {
  value       = "kubectl -n ${var.redis_namespace} port-forward svc/redis-master 6379:6379"
  description = "Comando para expor o Redis localmente (redis-cli -h localhost)"
}

output "redis_connection_test" {
  value       = "kubectl -n ${var.redis_namespace} exec deploy/redis-master -- redis-cli ping"
  description = "Comando para testar conexao com o Redis (deve retornar PONG)"
}

output "redis_namespace" {
  value       = var.redis_namespace
  description = "Namespace onde o Redis esta instalado"
}

output "redis_service_name" {
  value       = "redis-master"
  description = "Nome do service principal do Redis"
}

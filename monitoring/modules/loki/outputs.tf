# ═══════════════════════════════════════════════════════════
# Loki - Outputs Úteis
# ═══════════════════════════════════════════════════════════
output "loki_url_internal" {
  value       = "http://loki.${var.loki_namespace}.svc.cluster.local:3100"
  description = "URL interna do Loki (usada pelo Grafana e pelos agents de coleta de logs)"
}

output "loki_query_example" {
  value       = "{namespace=\"${var.loki_namespace}\"}"
  description = "Query de exemplo para testar no Loki (logs do namespace monitoring)"
}

output "loki_service_name" {
  value       = "loki"
  description = "Nome do service Kubernetes do Loki"
}

output "loki_namespace" {
  value       = var.loki_namespace
  description = "Namespace onde o Loki está instalado"
}


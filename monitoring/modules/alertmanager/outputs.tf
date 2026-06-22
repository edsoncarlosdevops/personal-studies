# ═══════════════════════════════════════════════════════════
# Alertmanager - Outputs Úteis
# ═══════════════════════════════════════════════════════════

output "alertmanager_service_name" {
  value       = "alertmanager"
  description = "Nome do service Kubernetes do Alertmanager"
}

output "alertmanager_namespace" {
  value       = var.alertmanager_namespace
  description = "Namespace onde o Alertmanager está instalado"
}

output "alertmanager_url_internal" {
  value       = "http://alertmanager.${var.alertmanager_namespace}.svc.cluster.local:9093"
  description = "URL interna do Alertmanager (usada pelo Prometheus para disparar alertas)"
}

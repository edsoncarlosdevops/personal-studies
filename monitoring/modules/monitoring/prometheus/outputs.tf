# ═══════════════════════════════════════════════════════════
# Prometheus - Outputs Úteis
# ═══════════════════════════════════════════════════════════
output "prometheus_url_internal" {
  value       = "http://prometheus-server.${var.prometheus_namespace}.svc.cluster.local:80"
  description = "URL interna do Prometheus (usada por outros serviços como OpenCost e Grafana)"
}

output "prometheus_port_forward_command" {
  value       = "kubectl -n ${var.prometheus_namespace} port-forward svc/prometheus-server 9090:80"
  description = "Comando para expor o Prometheus localmente (http://localhost:9090)"
}

output "prometheus_query_example" {
  value       = "up"
  description = "Query de exemplo para testar no Prometheus (todos os targets estao UP?)"
}

output "prometheus_service_name" {
  value       = "prometheus-server"
  description = "Nome do service Kubernetes do Prometheus"
}

output "prometheus_namespace" {
  value       = var.prometheus_namespace
  description = "Namespace onde o Prometheus está instalado"
}


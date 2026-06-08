output "grafana_url" {
  value       = "http://grafana.${var.grafana_namespace}.svc.cluster.local:80"
  description = "URL interna do Grafana no cluster"
}

output "grafana_service_name" {
  value       = "grafana"
  description = "Nome do service do Grafana"
}

output "grafana_namespace" {
  value       = var.grafana_namespace
  description = "Namespace do Grafana"
}

# ═══════════════════════════════════════════════════════════
# Thanos - Outputs Uteis
# ═══════════════════════════════════════════════════════════

output "thanos_query_url_internal" {
  value       = "http://thanos-query.${var.thanos_namespace}.svc.cluster.local:9090"
  description = "URL interna do Thanos Query (usada pelo Grafana como datasource Prometheus)"
}

output "thanos_store_url" {
  value       = "thanos-store.${var.thanos_namespace}.svc.cluster.local:10901"
  description = "URL gRPC do Thanos Store (consulta de dados historicos)"
}

output "thanos_query_port_forward_command" {
  value       = "kubectl -n ${var.thanos_namespace} port-forward svc/thanos-query 9090:9090"
  description = "Comando para expor o Thanos Query localmente (http://localhost:9090)"
}

output "thanos_query_example" {
  value       = "up"
  description = "Query de exemplo para testar no Thanos Query (deve retornar todos os targets UP)"
}

output "thanos_bucket" {
  value       = var.thanos_objstore_bucket
  description = "Nome do bucket no object storage usado pelo Thanos"
}

output "thanos_namespace" {
  value       = var.thanos_namespace
  description = "Namespace onde o Thanos esta instalado"
}

output "thanos_service_name" {
  value       = "thanos-query"
  description = "Nome do service do Thanos Query (substitui o Prometheus no Grafana)"
}

output "thanos_grafana_datasource_config" {
  value       = <<-EOT
    # No datasource do Grafana, use a URL abaixo em vez do Prometheus:
    # name: Prometheus
    # url: http://thanos-query.${var.thanos_namespace}.svc.cluster.local:9090
    # type: prometheus
    # access: proxy
  EOT
  description = "Instrucao para configurar o Grafana para usar o Thanos Query como datasource"
}

# ═══════════════════════════════════════════════════════════
# Tempo - Outputs Úteis
# ═══════════════════════════════════════════════════════════
output "tempo_url_internal" {
  value       = "http://tempo.${var.tempo_namespace}.svc.cluster.local:3100"
  description = "URL interna do Tempo (usada pelo Grafana para tracing)"
}

output "tempo_service_name" {
  value       = "tempo"
  description = "Nome do service Kubernetes do Tempo"
}

output "tempo_namespace" {
  value       = var.tempo_namespace
  description = "Namespace onde o Tempo está instalado"
}

output "tempo_test_trace_command" {
  value = "kubectl run --image=curlimages/curl curl-test --rm -it --restart=Never -- sh -c 'curl -X POST http://tempo.${var.tempo_namespace}.svc.cluster.local:4318/v1/traces -H \"Content-Type: application/json\" -d \"{\\\"resourceSpans\\\":[]}\"'"
  description = "Comando para gerar um trace de teste no Tempo"
}


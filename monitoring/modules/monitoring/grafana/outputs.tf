# ═══════════════════════════════════════════════════════════
# Grafana - Outputs Úteis
# ═══════════════════════════════════════════════════════════

locals {
  # Busca a senha do admin do Grafana no Kubernetes
  grafana_admin_password_cmd = "kubectl get secret -n ${var.grafana_namespace} grafana -o jsonpath='{.data.admin-password}' | base64 -d"
}

output "grafana_url_internal" {
  value       = "http://grafana.${var.grafana_namespace}.svc.cluster.local:80"
  description = "URL interna do Grafana (acessível de dentro do cluster)"
}

output "grafana_url_port_forward" {
  value       = "http://localhost:3000"
  description = "URL para acessar o Grafana via port-forward (kubectl port-forward)"
}

output "grafana_port_forward_command" {
  value       = "kubectl -n ${var.grafana_namespace} port-forward svc/grafana 3000:80"
  description = "Comando para expor o Grafana localmente via port-forward"
}

output "grafana_admin_login" {
  value       = "admin"
  description = "Usuário admin do Grafana"
}

output "grafana_get_password_command" {
  value       = local.grafana_admin_password_cmd
  description = "Comando para obter a senha do admin do Grafana"
}

output "grafana_namespace" {
  value       = var.grafana_namespace
  description = "Namespace onde o Grafana está instalado"
}

output "grafana_service_name" {
  value       = "grafana"
  description = "Nome do service Kubernetes do Grafana"
}

output "grafana_datasources" {
  value = {
    prometheus = "http://prometheus-server.${var.grafana_namespace}.svc.cluster.local:80"
    loki       = "http://loki.${var.grafana_namespace}.svc.cluster.local:3100"
    tempo      = "http://tempo.${var.grafana_namespace}.svc.cluster.local:3100"
  }
  description = "URLs das sources de dados configuradas no Grafana"
}


# ArgoCD - Outputs Uteis
#
# Estes outputs sao usados por outros modulos ou pelo root module
# para obter informacoes sobre a instalacao do ArgoCD.

output "argocd_namespace" {
  value       = var.argocd_namespace
  description = "Namespace onde o ArgoCD foi instalado"
}

output "argocd_url_internal" {
  value       = "https://argocd-server.${var.argocd_namespace}.svc.cluster.local:443"
  description = "URL interna do ArgoCD Server (usada por outras aplicacoes no cluster)"
}

output "argocd_url_port_forward" {
  value       = "http://localhost:8080"
  description = "URL local apos executar o port-forward"
}

output "argocd_url_ingress" {
  value       = var.argocd_ingress_enabled ? "https://${var.argocd_domain}" : "Ingress nao habilitado"
  description = "URL do ArgoCD via Ingress (se habilitado)"
}

output "argocd_get_password_command" {
  value       = "kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
  description = "Comando para obter a senha do admin do ArgoCD"
}

output "argocd_port_forward_command" {
  value       = "kubectl -n ${var.argocd_namespace} port-forward svc/argocd-server 8080:443"
  description = "Comando para expor o ArgoCD localmente (http://localhost:8080)"
}

output "argocd_login_command" {
  value       = "argocd login localhost:8080 --username admin --password $(kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d)"
  description = "Comando para fazer login no ArgoCD via CLI (apos port-forward)"
}

output "argocd_service_name" {
  value       = "argocd-server"
  description = "Nome do service principal do ArgoCD"
}

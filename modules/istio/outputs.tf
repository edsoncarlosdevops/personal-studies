# ═══════════════════════════════════════════════════════════
# Istio - Outputs Uteis
# ═══════════════════════════════════════════════════════════

output "istio_ingress_gateway_url" {
  value       = var.istio_ingress_gateway_enabled ? "istio-ingressgateway.${var.istio_namespace}.svc.cluster.local" : "Istio Ingress Gateway desabilitado"
  description = "URL interna do Istio Ingress Gateway"
}

output "istio_ingress_gateway_external_ip" {
  value       = var.istio_ingress_gateway_enabled ? "kubectl -n ${var.istio_namespace} get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" : "N/A (gateway desabilitado)"
  description = "Comando para obter o IP externo do Istio Ingress Gateway"
}

output "istio_enable_injection_command" {
  value       = "kubectl label namespace <NAMESPACE> istio-injection=enabled"
  description = "Comando para habilitar sidecar injection em um namespace"
}

output "istio_disable_injection_command" {
  value       = "kubectl label namespace <NAMESPACE> istio-injection-"
  description = "Comando para desabilitar sidecar injection em um namespace"
}

output "istio_restart_deployments_command" {
  value       = "kubectl rollout restart deployment -n <NAMESPACE>"
  description = "Comando para recriar pods com sidecar Envoy apos habilitar injection"
}

output "istio_check_injection_command" {
  value       = "kubectl get pods -n <NAMESPACE> -o jsonpath='{range .items[*]}{.metadata.name}{\"\\t\"}{.spec.containers[*].name}{\"\\n\"}{end}' | grep istio-proxy"
  description = "Comando para verificar se os pods tem o sidecar Envoy (deve mostrar istio-proxy)"
}

output "istio_version_check" {
  value       = "kubectl -n ${var.istio_namespace} exec deploy/istiod -- pilot-discovery version"
  description = "Comando para verificar a versao do Istio instalada"
}

output "istio_dashboard_url" {
  value       = "https://grafana.com/grafana/dashboards/?search=istio"
  description = "URL com dashboards Grafana prontos para Istio (importar manualmente)"
}

output "istio_kiali_command" {
  value       = "kubectl port-forward -n istio-system svc/kiali 20001:20001 (requer instalacao separada do Kiali)"
  description = "Comando para acessar o Kiali (UI do Istio) se estiver instalado"
}

output "istio_namespace" {
  value       = var.istio_namespace
  description = "Namespace onde o Istio esta instalado"
}

output "istio_mtls_mode" {
  value       = var.istio_mtls_mode
  description = "Modo mTLS configurado (PERMISSIVE, STRICT, DISABLE)"
}

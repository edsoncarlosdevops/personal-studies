output "app_service_name" {
  description = "Kubernetes service name for the app"
  value       = kubernetes_service.app.metadata[0].name
}

output "app_namespace" {
  description = "Namespace where the app is deployed"
  value       = kubernetes_namespace.app.metadata[0].name
}

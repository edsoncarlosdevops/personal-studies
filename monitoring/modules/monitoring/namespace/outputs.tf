output "namespace_name" {
  value       = kubernetes_namespace_v1.monitoring.metadata[0].name
  description = "Nome do namespace criado"
}

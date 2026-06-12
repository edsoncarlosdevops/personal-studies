output "promtail_namespace" {
  value = var.promtail_namespace
}

output "promtail_release_name" {
  value = helm_release.promtail.name
}

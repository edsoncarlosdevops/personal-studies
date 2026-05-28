output "argocd_namespace" {
  value = "argocd"
}

output "get_admin_password" {
  value = "Execute: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
}

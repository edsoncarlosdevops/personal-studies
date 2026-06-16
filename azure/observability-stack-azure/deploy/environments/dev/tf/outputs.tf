output "cluster_name" {
  value = module.aks.cluster_name
}

output "cluster_id" {
  value = module.aks.cluster_id
}

output "vnet_id" {
  value = module.aks.vnet_id
}

output "postgresql_fqdn" {
  value = module.postgresql.fqdn
}

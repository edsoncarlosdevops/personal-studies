output "bastion_public_ip" {
  description = "IP do Bastion pra conectar via SSH"
  value       = module.bastion.bastion_public_ip
}

output "eks_cluster_name" {
  description = "Nome do cluster EKS"
  value       = module.eks.cluster_name
}

output "rds_endpoint" {
  description = "Endpoint do PostgreSQL"
  value       = module.rds.db_endpoint
}

output "ssh_command" {
  description = "Comando pra conectar no Bastion"
  value       = "ssh -i bastion-key.pem ec2-user@${module.bastion.bastion_public_ip}"
}

output "kubectl_command" {
  description = "Comando pra configurar kubectl (rode no Bastion)"
  value       = "aws eks update-kubeconfig --region us-east-1 --name ${module.eks.cluster_name}"
}

output "psql_command" {
  description = "Comando pra conectar no banco (rode no Bastion)"
  value       = "psql -h ${module.rds.db_endpoint} -U ${module.rds.db_username} -d ${module.rds.db_name}"
}

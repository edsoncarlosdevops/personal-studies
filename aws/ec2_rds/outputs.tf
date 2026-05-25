output "vpc_id" {
  description = "ID da VPC"
  value       = module.vpc.vpc_id
}

output "subnet_ids" {
  description = "IDs das subnets criadas (lista)"
  value       = module.vpc.subnet_ids
}

# O endpoint do RDS vem completo (host:porta), tipo:
# "mydb.xxxxxx.us-east-1.rds.amazonaws.com:3306"
# Se precisar do host e porta separados, o módulo RDS já tem
# os outputs db_instance_endpoint e db_instance_port.
output "rds_endpoint" {
  description = "Endpoint de conexão do RDS (host:porta)"
  value       = module.rds.db_instance_endpoint
}

output "ec2_public_ip" {
  description = "IP público da EC2 (use para acessar via navegador)"
  value       = module.ec2.ec2_public_ip
}


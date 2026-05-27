output "db_instance_id" {
  description = "ID da instância RDS"
  value       = aws_db_instance.this.id
}

output "db_endpoint" {
  description = "Endpoint de conexão do banco"
  value       = aws_db_instance.this.endpoint
}

output "db_port" {
  description = "Porta do banco"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Nome do banco"
  value       = aws_db_instance.this.db_name
}

output "db_username" {
  description = "Usuário master"
  value       = aws_db_instance.this.username
}

output "db_security_group_id" {
  description = "ID do security group do RDS"
  value       = aws_security_group.rds.id
}

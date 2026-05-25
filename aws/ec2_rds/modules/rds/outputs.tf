output "db_instance_id" {
  value       = aws_db_instance.this.id
  description = "ID da instância RDS criada"
}

output "db_instance_endpoint" {
  value       = aws_db_instance.this.endpoint
  description = "Endpoint da instância RDS para conexão"
}

output "db_instance_port" {
  value       = aws_db_instance.this.port
  description = "Porta da instância RDS para conexão"
}


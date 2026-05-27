variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC onde o RDS será criado"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs das subnets privadas para o DB subnet group"
  type        = list(string)
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Usuário master do banco"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Senha do banco (recomendado usar Secrets Manager)"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Armazenamento alocado em GB"
  type        = number
  default     = 20
}

variable "engine_version" {
  description = "Versão do PostgreSQL"
  type        = string
  default     = "16.3"
}

variable "allowed_cidr" {
  description = "CIDR permitido para acessar o banco"
  type        = string
  default     = "0.0.0.0/0"
}

variable "db_subnet_ids" {
  description = "List of subnet IDs for the RDS DB subnet group"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "VPC ID where the RDS instance will be deployed"
  type        = string
  default     = ""
}

variable "db_name" {
  description = "Name of the RDS database"
  type        = string
  default     = "mydb"
}

variable "db_username" {
  description = "Master username for the RDS database"
  type        = string
  default     = "admin"
}

# Cuidado: senha hardcoded não é uma boa prática.
# Para estudos até vai, mas em produção o ideal é:
# - Não ter default (obriga passar por fora)
# - Usar AWS Secrets Manager
# - Ou passar via TF_VAR_db_password
variable "db_password" {
  description = "Master password for the RDS database"
  type        = string
  default     = "password"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "allocated_storage" {
  description = "Allocated storage in GB for the RDS instance"
  type        = number
  default     = 20
}

variable "storage_type" {
  description = "Storage type for the RDS instance (e.g., gp2, io1)"
  type        = string
  default     = "gp2"
}

variable "engine" {
  description = "Database engine (e.g., mysql, postgres)"
  type        = string
  default     = "mysql"
}

variable "engine_version" {
  description = "Version of the database engine"
  type        = string
  default     = "8.0"
}

variable "instance_class" {
  description = "Instance class for the RDS instance (e.g., db.t3.micro)"
  type        = string
  default     = "db.t3.micro"
}

variable "parameter_group_name" {
  description = "Name of the DB parameter group to associate with the RDS instance"
  type        = string
  default     = "default.mysql8.0"
}


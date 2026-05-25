variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "subnets" {
  description = "Map of subnets to create"
  # Nota: map(any) aceita qualquer estrutura, sem validar campos.
  # Adicionei availability_zone nas subnets porque o RDS exige
  # pelo menos 2 AZs diferentes no DB subnet group.
  type    = map(any)
  default = {
    "subnet-a" = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-1a"
    }
    "subnet-b" = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-east-1b"
    }
  }
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

variable "db_password" {
  description = "Master password for the RDS database"
  # Senha hardcoded não é ideal - prefira passar via tfvars
  type    = string
  default = "password"
}
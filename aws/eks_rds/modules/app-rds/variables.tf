variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "db_endpoint" {
  description = "RDS PostgreSQL endpoint"
  type        = string
}

variable "db_port" {
  description = "RDS PostgreSQL port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "app_image" {
  description = "Docker image for the app"
  type        = string
  default     = "edsoncarlosdevops/app-rds:latest"
}

variable "app_replicas" {
  description = "Number of app replicas"
  type        = number
  default     = 1
}


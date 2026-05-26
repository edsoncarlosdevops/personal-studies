variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "sufixo" {
  description = "Sufixo para tornar o nome do bucket único globalmente"
  type        = string
  default     = "001"
}


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
  # Nota: map(any) aceita qualquer coisa, então não valida se a estrutura está certa.
  # Se quiser mais segurança, troque para:
  # map(object({ cidr_block = string }))
  # Exemplo de uso:
  # {
  #   "subnet-a" = { cidr_block = "10.0.1.0/24" }
  #   "subnet-b" = { cidr_block = "10.0.2.0/24" }
  # }
  type    = map(any)
  default = {}
}


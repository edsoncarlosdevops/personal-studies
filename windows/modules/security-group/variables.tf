variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "allowed_rdp_cidr" {
  description = "CIDR block allowed for RDP access"
  type        = string
  default     = "0.0.0.0/0"
}

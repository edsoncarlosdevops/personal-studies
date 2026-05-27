variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC onde o bastion será criado"
  type        = string
}

variable "public_subnet_id" {
  description = "ID da subnet pública para o bastion"
  type        = string
}

variable "bastion_ami" {
  description = "AMI do Amazon Linux 2"
  type        = string
  default     = "ami-0c02fb55956c7d316" # Amazon Linux 2 us-east-1
}

variable "instance_type" {
  description = "Tipo da instância"
  type        = string
  default     = "t3.micro"
}

variable "allowed_ssh_cidr" {
  description = "CIDR permitido para SSH"
  type        = string
  default     = "0.0.0.0/0"
}

variable "key_name" {
  description = "Nome do key pair EC2"
  type        = string
}

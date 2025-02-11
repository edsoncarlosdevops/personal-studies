variable "region" {
  description = "Região da AWS"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "Tipo de instância EC2"
  default     = "t3.small"
}

# Adicione esta variável nova no variables.tf
variable "ssh_user" {
  description = "Usuário SSH padrão para a AMI"
  default     = "ec2-user"  # Alterado de 'centos' para 'cloud-user'
}

variable "cidr_block_vpc" {
  description = "CIDR block da VPC"
  default     = "10.0.0.0/16"
  
}

variable "cidr_block_subnet" {
  description = "CIDR block da Subnet"
  default     = "10.0.1.0/24"
  
}

variable "key_name" {
  description = "Nome da chave SSH"
  default     = "centos-dev"
  
}

variable "security_group_name" {
  description = "Nome do security group"
  default     = "centos-stream-sg"
  
}

variable "ami" {
  description = "ID da AMI"
  default     = "ami-0c3fd0f5d33134a76"
  
}
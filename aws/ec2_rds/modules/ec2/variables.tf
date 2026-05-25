variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID onde a EC2 será implantada"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID para criar o security group"
  type        = string
}

variable "ami_id" {
  description = "AMI ID para a EC2"
  type        = string
  default     = "ami-0d5f5816aec344215" # Amazon Linux 2
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t2.micro"
}

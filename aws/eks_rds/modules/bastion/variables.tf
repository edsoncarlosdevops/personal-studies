variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed for SSH"
  type        = string
  default     = "0.0.0.0/0"
}

variable "bastion_ami" {
  description = "AMI ID"
  type        = string
  default     = "ami-0c02fb55956c7d316"
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.micro"
}

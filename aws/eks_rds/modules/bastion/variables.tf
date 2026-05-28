variable "environment" {
  type    = string
}

variable "vpc_id" {
  type    = string
}

variable "public_subnet_id" {
  type    = string
}

variable "key_name" {
  type    = string
}

variable "allowed_ssh_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "bastion_ami" {
  type    = string
  default = "ami-0c02fb55956c7d316"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

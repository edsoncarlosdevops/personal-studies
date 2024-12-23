variable "region" {
  description = "The AWS region to deploy resources."
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "The name of the VPC."
  default     = "two-tier-vpc"
}

variable "public_subnet_1_cidr" {
  description = "The CIDR block for the public subnet 1."
  default     = "10.0.0.0/24"
}

variable "public_subnet_2_cidr" {
  description = "The CIDR block for the public subnet 2."
  default     = "10.0.1.0/24"
}

variable "subnet_1_az" {
  description = "The availability zone for the public subnet 1."
  default     = "us-east-1a"
}

variable "subnet_2_az" {
  description = "The availability zone for the public subnet 2."
  default     = "us-east-1b"
}

variable "ig_name" {
  description = "The name of the internet gateway."
  default     = "two-tier-ig"
}

variable "public_rt_name" {
  description = "The name of the public route table."
  default     = "two-tier-public-rt"
}

variable "private_subnet_1_cidr" {
  description = "The CIDR block for the private subnet 1."
  default     = "10.0.2.0/24"
}

variable "private_subnet_2_cidr" {
  description = "The CIDR block for the private subnet 2."
  default     = "10.0.3.0/24"
}

variable "alb_sg_name" {
  description = "The name of the security group for the ALB."
  default     = "two-tier-alb-sg"
}

variable "sg_name" {
  description = "The name of the security group."
  default     = "two-tier-sg"
}

variable "db_sg_name" {
  description = "The name of the security group for the RDS instance."
  default     = "two-tier-db-sg"
}

variable "lb_name" {
  description = "The name of the load balancer."
  default     = "two-tier-alb"
}

variable "tg_name" {
  description = "The name of the target group."
  default     = "two-tier-tg"
}

variable "ami_id" {
  description = "The ID of the AMI."
  default     = "ami-0c02fb55956c7d316"
}

variable "instance_type" {
  description = "The instance type."
  default     = "t2.micro"
}

variable "key_name" {
  description = "The name of the key pair."
  default     = "test-app-key"
}

variable "db_subnet" {
  description = "The name of the DB subnet group."
  default     = "two-tier-db-subnet"
}

variable "db_username" {
  description = "Username for db instance"
}

variable "db_password" {
  description = "Password for db instance"
}
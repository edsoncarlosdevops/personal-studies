output "vpc_id" {
description = "The ID of the VPC"
  value = aws_vpc.this.id
}


output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public.*.id
}   

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private.*.id
}

output "public_subnets_cidrs" {
  description = "CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnets_cidrs" {
  description = "CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}
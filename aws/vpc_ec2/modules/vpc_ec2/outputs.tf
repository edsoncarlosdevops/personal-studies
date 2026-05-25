output "vpc_id" {
  description = "The ID of the VPC created for the environment."
  value       = aws_vpc.this.id
  
}

output "ec2_ip_address" {
  description = "The public IP address of the EC2 instance in the environment."
  value       = aws_instance.this.public_ip
}
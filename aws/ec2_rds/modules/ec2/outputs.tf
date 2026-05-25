output "ec2_id" {
  description = "ID da instância EC2"
  value       = aws_instance.this.id
}

output "ec2_public_ip" {
  description = "IP público da instância EC2"
  value       = aws_instance.this.public_ip
}

output "ec2_sg_id" {
  description = "ID do security group da EC2"
  value       = aws_security_group.ec2_sg.id
}

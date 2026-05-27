output "bastion_id" {
  description = "ID da instância bastion"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "IP público do bastion"
  value       = aws_instance.bastion.public_ip
}

output "bastion_security_group_id" {
  description = "ID do security group do bastion"
  value       = aws_security_group.bastion.id
}

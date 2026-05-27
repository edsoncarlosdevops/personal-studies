output "bastion_id" {
  description = "Bastion instance ID"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Bastion public IP"
  value       = aws_instance.bastion.public_ip
}

output "bastion_security_group_id" {
  description = "Bastion security group ID"
  value       = aws_security_group.bastion.id
}

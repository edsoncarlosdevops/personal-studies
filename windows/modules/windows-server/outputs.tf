output "instance_id" {
  value = aws_instance.windows.id
}

output "public_ip" {
  value = aws_instance.windows.public_ip
}

output "private_ip" {
  value = aws_instance.windows.private_ip
}


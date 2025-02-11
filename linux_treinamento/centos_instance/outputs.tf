output "public_ip" {
  value = aws_instance.centos.public_ip
}

output "ssh_connection" {
  value = "ssh -i centos-dev.pem ${var.ssh_user}@${aws_instance.centos.public_ip}"
}

output "private_key_warning" {
  value = "Chave privada salva em: centos-dev.pem (MANTENHA SEGURA!)"
}
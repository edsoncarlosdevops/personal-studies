# Atualize o bloco aws_instance para incluir metadados cloud-init
resource "aws_instance" "centos" {
  ami                    = var.ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.centos_sg.id]
  key_name               = aws_key_pair.dev_key.key_name
  subnet_id              = aws_subnet.main.id
  associate_public_ip_address = true

  # Adicione este bloco user_data para garantir a configuração do SSH
  user_data = <<-EOF
    #!/bin/bash
    echo "${tls_private_key.dev_key.public_key_openssh}" >> /home/${var.ssh_user}/.ssh/authorized_keys
    chmod 600 /home/${var.ssh_user}/.ssh/authorized_keys
    chown ${var.ssh_user}:${var.ssh_user} /home/${var.ssh_user}/.ssh/authorized_keys
  EOF

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  tags = {
    Name = "CentOS-Stream-Training"
  }
}

resource "tls_private_key" "dev_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.dev_key.private_key_pem
  filename        = "${path.module}/centos-dev.pem"
  file_permission = "0400"
}

resource "aws_key_pair" "dev_key" {
  key_name   = "centos-dev-key"
  public_key = tls_private_key.dev_key.public_key_openssh
}
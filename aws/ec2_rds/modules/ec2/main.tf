# Um aviso: as portas 22 (SSH) e 80 (HTTP) estão liberadas para qualquer IP.
# Se for deployar algo mais sério, restrinja o SSH apenas ao seu IP
# trocando o cidr_blocks por algo como ["SEU_IP_AQUI/32"].
resource "aws_security_group" "ec2_sg" {
  name        = "${var.environment}-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-ec2-sg" }
}

# Outra coisa: a EC2 está em uma única subnet.
# Se quiser alta disponibilidade, precisaria de mais instâncias
# distribuídas entre as subnets disponíveis.
resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  security_groups = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello from EC2 - ${var.environment}" > /var/www/html/index.html
              EOF

  tags = { Name = "${var.environment}-ec2-instance" }
}


resource "aws_security_group" "this" {
  name        = "${var.environment}-sg"
  description = "Security group for ${var.environment} environment"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "${var.environment}-sg" }

    ingress {
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]

    }
}


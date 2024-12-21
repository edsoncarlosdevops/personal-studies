terraform {
  backend "s3" {
    bucket         = "remote-state-edsoncarlos"
    key            = "security-group/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

resource "aws_security_group" "example" {
  name        = "example-sg-edson"
  description = "Example security group"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Example Security Group"
  }
}
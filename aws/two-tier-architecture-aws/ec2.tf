resource "aws_instance" "instance_1" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  key_name        = var.key_name
  subnet_id       = aws_subnet.public_subnet_1.id
  security_groups = [aws_security_group.sg.id]
  user_data       = filebase64("userdata.sh")

  tags = {
    Name = "instance_1"
  }

}

resource "aws_instance" "instance_2" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  key_name        = var.key_name
  subnet_id       = aws_subnet.public_subnet_2.id
  security_groups = [aws_security_group.sg.id]
  user_data       = filebase64("userdata.sh")

  tags = {
    Name = "instance_2"
  }

}
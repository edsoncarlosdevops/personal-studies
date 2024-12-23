resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.private_subnet_1_cidr
  availability_zone       = var.subnet_1_az
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}-private-subnet_1"
  }

}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.private_subnet_2_cidr
  availability_zone       = var.subnet_2_az
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}-private-subnet_2"
  }

}


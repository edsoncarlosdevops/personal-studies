resource "aws_db_subnet_group" "subnet_group" {
  name       = var.db_subnet
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  tags = {
    Name = "mydb_subnet_group"
  }

}
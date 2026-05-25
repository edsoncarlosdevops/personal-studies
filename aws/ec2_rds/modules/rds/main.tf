# Data source para buscar informações da VPC usando o ID passado como variável
# Fiz assim porque antes tinha uma expressão complicada:
#   data.aws_vpc.selected.cidr_block == var.vpc_cidr_block ? [...] : [...]
# Além de feia, dava erro porque a variável vpc_cidr_block nem existia.
# O data source busca a VPC pelo ID (que já passamos) e extrai o cidr_block
# direto da AWS. Mais simples e resolve o problema.
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Um ponto importante: skip_final_snapshot = true é prático para testes
# porque você consegue destruir e recriar sem acumular snapshots.
# Mas em produção, remova essa linha para não perder dados se alguém
# der um destroy sem querer.
resource "aws_db_instance" "this" {
  identifier              = "${var.environment}-rds"
  allocated_storage       = var.allocated_storage
  storage_type            = var.storage_type
  engine                  = var.engine
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  parameter_group_name    = var.parameter_group_name
  skip_final_snapshot     = true # repensar em produção

  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = { Name = "${var.environment}-rds" }
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.environment}-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  # Permite tráfego MySQL (3306) apenas DENTRO da VPC
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

    tags = { Name = "${var.environment}-rds-sg" }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.environment}-rds-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = { Name = "${var.environment}-rds-subnet-group" }
}



# main.tf - Conecta os módulos VPC, RDS e EC2
#
# O módulo VPC expõe seus recursos via outputs,
# e o main.tf raiz passa esses outputs como input para os módulos RDS e EC2

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr_block = var.vpc_cidr_block
  environment    = var.environment
  subnets        = var.subnets
}

# Repare que o módulo RDS só está recebendo algumas variáveis.
# As outras (allocated_storage, instance_class, engine, etc.)
# estão usando os defaults do módulo. Se quiser mudar algo,
# é só adicionar os parâmetros aqui.
module "rds" {
  source = "./modules/rds"

  vpc_id        = module.vpc.vpc_id
  db_subnet_ids = module.vpc.subnet_ids
  # Uso module.vpc.vpc_id e module.vpc.subnet_ids para garantir que o RDS
  # seja criado na mesma VPC que as subnets. O erro anterior aconteceu porque
  # o RDS estava tentando usar uma VPC diferente (provavelmente de outro teste).

  environment = var.environment
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}

# Só um lembrete: a EC2 está na primeira subnet da lista.
# Se quiser distribuir instâncias entre várias subnets,
# daria pra usar count ou for_each com module.vpc.subnet_ids.
module "ec2" {
  source = "./modules/ec2"

  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_id   = module.vpc.subnet_ids[0]
}
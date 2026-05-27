# ---- VPC ----
module "vpc" {
  source = "../../modules/vpc"

  environment           = "dev"
  vpc_cidr_block        = "10.0.0.0/16"
  public_subnets_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  availability_zones    = ["us-east-1a", "us-east-1b"]
}

# ---- EKS ----
module "eks" {
  source = "../../modules/eks"

  environment         = "dev"
  k8s_version         = "1.30"
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  node_desired_size   = 2
  node_min_size       = 1
  node_max_size       = 3
  node_instance_types = ["t3.medium"]
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
}

# ---- RDS ----
resource "random_password" "db_password" {
  length  = 16
  special = false
}

module "rds" {
  source = "../../modules/rds"

  environment        = "dev"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  db_name            = "appdb"
  db_username        = "admin"
  db_password        = random_password.db_password.result
  allowed_cidr       = "10.0.0.0/16"
}

# ---- BASTION ----
resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion" {
  key_name   = "dev-bastion-key"
  public_key = tls_private_key.bastion.public_key_openssh
}

resource "local_file" "bastion_private_key" {
  content         = tls_private_key.bastion.private_key_pem
  filename        = "./bastion-key.pem"
  file_permission = "0600"
}

module "bastion" {
  source = "../../modules/bastion"

  environment      = "dev"
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids[0]
  key_name         = aws_key_pair.bastion.key_name
  allowed_ssh_cidr = "0.0.0.0/0"
}

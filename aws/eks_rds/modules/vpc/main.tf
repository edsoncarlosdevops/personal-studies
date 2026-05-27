# =============================================
# 🌐 Módulo VPC - Rede completa pra vida adulta
# =============================================
# Esse módulo cria uma VPC com subnets públicas
# (pra galera que precisa de internet) e privadas
# (pros serviços que não podem ser expostos).
# Ainda leva um NAT Gateway pra dar acesso
# à internet pras subnets privadas.
# =============================================

# --- VPC principal ---
# A base de tudo. Sem ela, nada funciona.
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.environment}-vpc" }
}

# --- Subnets públicas ---
# Onde vão: Load Balancers, Bastion, NAT Gateway
# Têm rota direta pro Internet Gateway
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "${var.environment}-public-${count.index + 1}" }
}

# --- Subnets privadas ---
# Onde vão: EKS nodes, RDS, serviços internos
# Sem IP público, seguras, acesso internet via NAT
resource "aws_subnet" "private" {
  count             = length(var.private_subnets_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = { Name = "${var.environment}-private-${count.index + 1}" }
}

# --- Internet Gateway ---
# A porta de entrada (e saída) pra internet
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.environment}-igw" }
}

# --- Elastic IP e NAT Gateway ---
# NAT = Network Address Translation
# Permite que recursos privados acessem a internet
# (pra baixar pacotes, atualizações, etc)
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.environment}-nat-eip" }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = { Name = "${var.environment}-nat" }
}

# --- Route Tables ---
# Public: rota direta pro IGW (0.0.0.0/0)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.environment}-public-rt" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private: rota pro NAT (acesso controlado)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.environment}-private-rt" }
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

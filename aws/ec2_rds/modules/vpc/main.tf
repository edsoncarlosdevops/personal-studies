resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block

  tags = { Name = "${var.environment}-vpc" }
  
}

# Vale notar: as subnets não têm availability_zone definida, então a AWS escolhe automaticamente.
# Dependendo da região, todas podem cair na mesma AZ, o que não é ideal para o RDS.
# Se quiser controlar, adicione availability_zone no map de subnets.
resource "aws_subnet" "this" {
  for_each   = var.subnets
  vpc_id     = aws_vpc.this.id
  cidr_block = each.value.cidr_block
  availability_zone = lookup(each.value, "availability_zone", null)
  # Fiz essa mudança porque o erro "DBSubnetGroupDoesNotCoverEnoughAZs" apareceu.
  # O RDS exige subnets em pelo menos 2 AZs diferentes, mas antes as subnets
  # não tinham availability_zone definida e a AWS colocou ambas na mesma AZ.
  # Agora cada subnet recebe a AZ definida no map de subnets.

  tags = { Name = "${var.environment}-subnet-${each.key}" }
}


resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.environment}-igw" }
}

resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.environment}-route-table" }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.this.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Aqui tem um detalhe: criamos a route table e a rota pra internet,
# mas as subnets não estão associadas a ela. Se a ideia é ter subnets
# públicas com acesso à internet, precisa do resource abaixo:
# resource "aws_route_table_association" "this" {
#   for_each       = aws_subnet.this
#   subnet_id      = each.value.id
#   route_table_id = aws_route_table.this.id
# }



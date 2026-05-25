output "vpc_id" {
  value       = aws_vpc.this.id
  description = "ID da VPC criada"
}

output "vpc_cidr_block" {
  value       = aws_vpc.this.cidr_block
  description = "CIDR block da VPC criada"
}

# Só um aviso: a ordem dos IDs pode variar porque o for_each não garante ordem.
# Isso é compatível com list(string) do RDS, mas se precisar de uma ordem
# previsível, use sort() ou um for explícito.
output "subnet_ids" {
  value       = values(aws_subnet.this)[*].id
  description = "Lista de IDs das subnets criadas"
}


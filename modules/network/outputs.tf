output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "nat_gateway_count" {
  description = "Nombre de NAT Gateways (chacune coûte ~33 $/mois)."
  value       = local.nat_count
}

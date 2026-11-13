output "vpc_id" {
  value = module.network.vpc_id
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "nat_gateway_count" {
  value = module.network.nat_gateway_count
}

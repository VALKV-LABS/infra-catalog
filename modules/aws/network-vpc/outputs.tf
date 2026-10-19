output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID."
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "Public subnet IDs."
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "Private subnet IDs."
}

output "availability_zones" {
  value       = local.az_names
  description = "Availability zones used by the stack."
}

output "vpc_cidr_block" {
  value       = aws_vpc.main.cidr_block
  description = "VPC CIDR block — needed by callers that peer another VPC to this one."
}

output "private_route_table_ids" {
  value       = aws_route_table.private[*].id
  description = "Private subnet route table IDs — needed to add a return route when another VPC peers to this one (e.g. BaaS's VPC, see baas/terraform/modules/region-infra)."
}

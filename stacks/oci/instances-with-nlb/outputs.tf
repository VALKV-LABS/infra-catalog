output "load_balancer_ip_addresses" {
  value       = module.nlb.nlb_ip_addresses
  description = "Public IP addresses of the OCI network load balancer."
}

output "instance_ids" {
  value       = module.compute.instance_ids
  description = "OCI instance IDs."
}

output "instance_private_ips" {
  value       = module.compute.instance_private_ips
  description = "Private IPs of the OCI instances."
}

output "vcn_id" {
  value       = module.network.vcn_id
  description = "VCN ID."
}

output "public_subnet_id" {
  value       = module.network.public_subnet_id
  description = "Public subnet ID."
}

output "private_subnet_id" {
  value       = module.network.private_subnet_id
  description = "Private subnet ID."
}

output "block_volume_ids" {
  value       = module.compute.block_volume_ids
  description = "Attached block volume IDs."
}

output "lb_dns_name" {
  value       = module.lb.lb_dns_name
  description = "DNS name of the application load balancer."
}

output "lb_zone_id" {
  value       = module.lb.lb_zone_id
  description = "Hosted zone ID for Route53 alias records."
}

output "instance_ids" {
  value       = module.compute.instance_ids
  description = "EC2 instance IDs."
}

output "instance_private_ips" {
  value       = module.compute.instance_private_ips
  description = "Private IPs of the compute instances."
}

output "instance_security_group_id" {
  value       = module.compute.security_group_id
  description = "Security group ID applied to the compute instances."
}

output "vpc_id" {
  value       = module.network.vpc_id
  description = "VPC ID."
}

output "public_subnet_ids" {
  value       = module.network.public_subnet_ids
  description = "Public subnet IDs."
}

output "private_subnet_ids" {
  value       = module.network.private_subnet_ids
  description = "Private subnet IDs."
}

output "ebs_volume_ids" {
  value       = module.compute.ebs_volume_ids
  description = "Attached EBS data volumes."
}

output "backup_policy_id" {
  value       = var.data_volume_enabled && var.backup_policy_enabled ? module.backup_policy[0].policy_id : null
  description = "ID of the EBS backup policy if enabled."
}

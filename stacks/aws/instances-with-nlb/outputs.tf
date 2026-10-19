output "lb_dns_name" {
  value       = module.nlb.lb_dns_name
  description = "DNS name of the network load balancer."
}

output "lb_zone_id" {
  value       = module.nlb.lb_zone_id
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

output "vpc_cidr_block" {
  value       = module.network.vpc_cidr_block
  description = "VPC CIDR block — needed by callers that peer another VPC to this one."
}

output "private_route_table_ids" {
  value       = module.network.private_route_table_ids
  description = "Private subnet route table IDs — needed to add a return route when another VPC peers to this one."
}

output "ebs_volume_ids" {
  value       = module.compute.ebs_volume_ids
  description = "Attached EBS data volumes."
}

output "backup_policy_id" {
  value       = var.data_volume_enabled && var.backup_policy_enabled ? module.backup_policy[0].policy_id : null
  description = "ID of the EBS backup policy if enabled."
}

output "instance_role_name" {
  value       = module.compute.iam_role_name
  description = "IAM role name attached to the compute instances. Use to attach additional policies."
}

output "instance_profile_name" {
  value       = module.compute.iam_instance_profile_name
  description = "IAM instance profile name attached to the compute instances."
}

output "availability_zones" {
  value       = module.network.availability_zones
  description = "AZs the subnets were spread across. Needed by anything carving a customer zone out of this VPC — infra-catalog/modules/aws/customer-zone sizes itself from this list."
}

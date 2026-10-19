output "subnet_ids" {
  value       = aws_subnet.this[*].id
  description = "Customer-dedicated subnets. What a control plane passes to RunInstances."
}

output "supernet" {
  value       = local.supernet
  description = "Summarized CIDR covering every customer subnet here. One route, not one per AZ — pass this to any tier that needs a return route."
}

output "route_table_ids" {
  value       = aws_route_table.this[*].id
  description = "This zone's own route tables. A peered tier needs routes to the supernet in ITS tables; these are the ones on this side."
}

output "security_group_ids" {
  value       = { for k, sg in aws_security_group.product : k => sg.id }
  description = "Per-product security group ids, keyed by product name."
}

output "iam_instance_profiles" {
  value       = { for k, p in aws_iam_instance_profile.product : k => p.name }
  description = "Per-product IAM instance profile names, keyed by product name."
}

output "network_acl_id" {
  value       = aws_network_acl.this.id
  description = "The NACL enforcing internet-yes, this-VPC-no on these subnets."
}

output "nat_public_ips" {
  value       = aws_eip.nat[*].public_ip
  description = "Egress IPs for customer traffic from this zone. These are what a customer's own upstream would see, so they are the addresses to hand out for allow-listing."
}

output "ssm_prefix" {
  value       = var.publish_to_ssm ? var.ssm_prefix : ""
  description = "Where this zone's ids were published, or empty when publication is off. Control planes read this prefix at runtime."
}

output "launch_template_ids" {
  value       = { for k, lt in aws_launch_template.product : k => lt.id }
  description = "Per-product launch template ids. Also published to SSM, which is how the control planes read them."
}

output "launch_template_versions" {
  value       = { for k, lt in aws_launch_template.product : k => lt.latest_version }
  description = "The version each product's control plane should launch. Pinned rather than $Latest, so an apply cannot change the shape of instances launched by a control plane nobody redeployed."
}

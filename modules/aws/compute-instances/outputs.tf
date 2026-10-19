output "instance_ids" {
  value       = [for instance in aws_instance.node : instance.id]
  description = "EC2 instance IDs."
}

output "instance_private_ips" {
  value       = [for instance in aws_instance.node : instance.private_ip]
  description = "Private IPs of the EC2 instances."
}

output "security_group_id" {
  value       = aws_security_group.instance.id
  description = "Security group applied to the instances."
}

output "iam_role_name" {
  value       = aws_iam_role.node.name
  description = "IAM role name attached to the instances."
}

output "iam_instance_profile_name" {
  value       = aws_iam_instance_profile.node.name
  description = "IAM instance profile attached to the instances."
}

output "ebs_volume_ids" {
  value       = [for volume in local.data_volumes : volume.id]
  description = "Attached data EBS volume IDs."
}

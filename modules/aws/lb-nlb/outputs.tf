output "lb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "DNS name of the network load balancer."
}

output "lb_arn" {
  value       = aws_lb.main.arn
  description = "ARN of the network load balancer."
}

output "lb_zone_id" {
  value       = aws_lb.main.zone_id
  description = "Hosted zone ID for Route53 alias records."
}

output "security_group_id" {
  value       = aws_security_group.lb.id
  description = "Security group ID for the NLB."
}

output "target_group_arn" {
  value       = aws_lb_target_group.service.arn
  description = "Target group ARN for the NLB listener."
}

output "extra_target_group_arns" {
  value       = { for k, v in aws_lb_target_group.extra : k => v.arn }
  description = "Target group ARNs for each entry in var.extra_listeners, keyed by listener name."
}

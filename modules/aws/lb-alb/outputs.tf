output "lb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "DNS name of the application load balancer."
}

output "lb_arn" {
  value       = aws_lb.main.arn
  description = "ARN of the application load balancer."
}

output "lb_zone_id" {
  value       = aws_lb.main.zone_id
  description = "Hosted zone ID for Route53 alias records."
}

output "security_group_id" {
  value       = aws_security_group.lb.id
  description = "Security group ID for the ALB."
}

output "target_group_arns" {
  value       = { for key, tg in aws_lb_target_group.services : key => tg.arn }
  description = "Target groups keyed by port."
}

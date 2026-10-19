output "lb_dns_name" {
  value       = module.app.lb_dns_name
  description = "DNS name of the application load balancer."
}

output "instance_ids" {
  value       = module.app.instance_ids
  description = "EC2 instance IDs."
}

output "postgresql_endpoint" {
  value       = module.postgresql.endpoint
  description = "RDS PostgreSQL endpoint hostname."
}

output "postgresql_port" {
  value       = module.postgresql.port
  description = "RDS PostgreSQL port."
}

output "postgresql_db_name" {
  value       = module.postgresql.db_name
  description = "Initial PostgreSQL database name."
}

output "postgresql_admin_username" {
  value       = module.postgresql.admin_username
  description = "Initial PostgreSQL admin username."
}

output "postgresql_master_user_secret_arn" {
  value       = module.postgresql.master_user_secret_arn
  description = "Secrets Manager ARN holding the managed master password."
}

output "postgresql_security_group_id" {
  value       = module.postgresql.security_group_id
  description = "Security group protecting the PostgreSQL instance."
}

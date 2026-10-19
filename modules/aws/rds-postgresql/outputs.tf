output "db_instance_id" {
  value       = aws_db_instance.this.id
  description = "RDS instance ID."
}

output "endpoint" {
  value       = aws_db_instance.this.address
  description = "RDS PostgreSQL endpoint hostname."
}

output "port" {
  value       = aws_db_instance.this.port
  description = "RDS PostgreSQL port."
}

output "db_name" {
  value       = aws_db_instance.this.db_name
  description = "Initial database name."
}

output "admin_username" {
  value       = aws_db_instance.this.username
  description = "Admin username."
}

output "master_user_secret_arn" {
  value       = try(aws_db_instance.this.master_user_secret[0].secret_arn, null)
  description = "Secrets Manager ARN for the managed master password."
}

output "security_group_id" {
  value       = aws_security_group.db.id
  description = "Security group protecting the database."
}

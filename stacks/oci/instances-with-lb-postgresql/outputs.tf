output "load_balancer_ip_addresses" {
  value       = module.app.load_balancer_ip_addresses
  description = "Public IP addresses of the OCI load balancer."
}

output "instance_ids" {
  value       = module.app.instance_ids
  description = "OCI instance IDs."
}

output "postgresql_db_system_id" {
  value       = module.postgresql.db_system_id
  description = "OCI PostgreSQL DB system ID."
}

output "postgresql_endpoint_fqdn" {
  value       = module.postgresql.primary_endpoint_fqdn
  description = "Primary PostgreSQL endpoint hostname."
}

output "postgresql_endpoint_port" {
  value       = module.postgresql.primary_endpoint_port
  description = "Primary PostgreSQL endpoint port."
}

output "postgresql_admin_username" {
  value       = module.postgresql.admin_username
  description = "PostgreSQL admin username."
}

output "postgresql_ca_certificate" {
  value       = module.postgresql.ca_certificate
  description = "CA certificate for PostgreSQL TLS."
  sensitive   = true
}

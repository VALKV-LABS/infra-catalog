output "db_system_id" {
  value       = oci_psql_db_system.this.id
  description = "OCI PostgreSQL DB system ID."
}

output "db_version" {
  value       = oci_psql_db_system.this.db_version
  description = "OCI PostgreSQL version."
}

output "admin_username" {
  value       = oci_psql_db_system.this.admin_username
  description = "PostgreSQL admin username."
}

output "primary_endpoint_fqdn" {
  value       = data.oci_psql_db_system_connection_detail.this.primary_db_endpoint[0].fqdn
  description = "Primary PostgreSQL endpoint hostname."
}

output "primary_endpoint_ip" {
  value       = data.oci_psql_db_system_connection_detail.this.primary_db_endpoint[0].ip_address
  description = "Primary PostgreSQL endpoint IP."
}

output "primary_endpoint_port" {
  value       = data.oci_psql_db_system_connection_detail.this.primary_db_endpoint[0].port
  description = "Primary PostgreSQL endpoint port."
}

output "reader_endpoint_fqdn" {
  value       = try(data.oci_psql_db_system_connection_detail.this.reader_endpoint[0].fqdn, null)
  description = "Reader PostgreSQL endpoint hostname when available."
}

output "ca_certificate" {
  value       = data.oci_psql_db_system_connection_detail.this.ca_certificate
  description = "CA certificate for PostgreSQL TLS."
  sensitive   = true
}

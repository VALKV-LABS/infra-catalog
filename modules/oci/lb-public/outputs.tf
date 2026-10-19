output "lb_id" {
  value       = oci_load_balancer_load_balancer.main.id
  description = "OCI load balancer ID."
}

output "lb_ip_addresses" {
  value       = [for ip in oci_load_balancer_load_balancer.main.ip_addresses : ip.ip_address]
  description = "Public IP addresses assigned to the load balancer."
}

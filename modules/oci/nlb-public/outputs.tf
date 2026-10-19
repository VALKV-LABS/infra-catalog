output "nlb_id" {
  value       = oci_network_load_balancer_network_load_balancer.main.id
  description = "OCI network load balancer ID."
}

output "nlb_ip_addresses" {
  value       = [for ip in oci_network_load_balancer_network_load_balancer.main.ip_addresses : ip.ip_address]
  description = "Public IP addresses assigned to the OCI network load balancer."
}

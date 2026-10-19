output "vcn_id" {
  value       = oci_core_vcn.main.id
  description = "VCN ID."
}

output "public_subnet_id" {
  value       = oci_core_subnet.public.id
  description = "Public subnet ID."
}

output "private_subnet_id" {
  value       = oci_core_subnet.private.id
  description = "Private subnet ID."
}

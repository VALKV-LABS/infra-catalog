output "instances" {
  value = {
    for key, instance in oci_core_instance.nodes : key => {
      id         = instance.id
      private_ip = instance.private_ip
    }
  }
  description = "Instances keyed by node name."
}

output "instance_ids" {
  value       = [for instance in oci_core_instance.nodes : instance.id]
  description = "OCI instance IDs."
}

output "instance_private_ips" {
  value       = [for instance in oci_core_instance.nodes : instance.private_ip]
  description = "Private IPs of the OCI instances."
}

output "block_volume_ids" {
  value       = [for volume in oci_core_volume.data : volume.id]
  description = "Attached block volume IDs."
}

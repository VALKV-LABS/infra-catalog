output "policy_id" {
  value       = aws_dlm_lifecycle_policy.data_volume.id
  description = "ID of the DLM lifecycle policy."
}

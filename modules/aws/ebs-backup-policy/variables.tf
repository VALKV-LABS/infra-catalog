variable "name_prefix" {
  type        = string
  description = "Prefix applied to resource names."
}

variable "stack_name" {
  type        = string
  description = "Stack label matched against EBS volume tags."
}

variable "backup_policy_name" {
  type        = string
  default     = "daily"
  description = "Backup label matched against EBS volume tags."
}

variable "snapshot_interval" {
  type        = number
  default     = 24
  description = "Snapshot interval for the DLM policy."
}

variable "snapshot_interval_unit" {
  type        = string
  default     = "HOURS"
  description = "Snapshot interval unit."
}

variable "snapshot_time_utc" {
  type        = string
  default     = "03:00"
  description = "UTC time for snapshot creation."
}

variable "retention_count" {
  type        = number
  default     = 7
  description = "How many snapshots to retain."
}

variable "copy_to_region" {
  type        = string
  default     = ""
  description = "Optional secondary AWS region for cross-region copy."
}

variable "copy_retention_interval" {
  type        = number
  default     = 7
  description = "Retention in days for cross-region copies."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}

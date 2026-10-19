variable "name_prefix" {
  type        = string
  description = "Prefix applied to resource names."
}

variable "compartment_id" {
  type        = string
  description = "OCI compartment OCID."
}

variable "subnet_id" {
  type        = string
  description = "Private subnet ID for the PostgreSQL system."
}

variable "db_version" {
  type        = string
  default     = "14"
  description = "OCI PostgreSQL database version."
}

variable "shape" {
  type        = string
  default     = "PostgreSQL.VM.Standard.E4.Flex"
  description = "OCI PostgreSQL shape name."
}

variable "instance_count" {
  type        = number
  default     = 1
  description = "Number of PostgreSQL instances."
}

variable "instance_ocpu_count" {
  type        = number
  default     = 1
  description = "OCPU count for each PostgreSQL instance."
}

variable "instance_memory_size_in_gbs" {
  type        = number
  default     = 16
  description = "Memory in GiB for each PostgreSQL instance."
}

variable "admin_username" {
  type        = string
  default     = "postgresadmin"
  description = "Initial PostgreSQL admin username."
}

variable "password_type" {
  type        = string
  default     = "PLAIN_TEXT"
  description = "Password source type. Use PLAIN_TEXT or VAULT_SECRET."
}

variable "admin_password" {
  type        = string
  default     = null
  description = "Admin password when password_type is PLAIN_TEXT."
  sensitive   = true
}

variable "admin_password_secret_id" {
  type        = string
  default     = null
  description = "Vault secret OCID when password_type is VAULT_SECRET."
}

variable "admin_password_secret_version" {
  type        = string
  default     = null
  description = "Vault secret version when password_type is VAULT_SECRET."
}

variable "storage_is_regionally_durable" {
  type        = bool
  default     = true
  description = "Whether PostgreSQL storage is regionally durable."
}

variable "storage_system_type" {
  type        = string
  default     = "OCI_OPTIMIZED_STORAGE"
  description = "OCI PostgreSQL storage type."
}

variable "storage_iops" {
  type        = number
  default     = 10000
  description = "IOPS for optimized storage."
}

variable "description" {
  type        = string
  default     = "Managed PostgreSQL provisioned by infra-catalog"
  description = "User-facing description for the PostgreSQL system."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}

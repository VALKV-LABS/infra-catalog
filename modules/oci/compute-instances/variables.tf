variable "name_prefix" {
  type        = string
  description = "Prefix applied to resource names."
}

variable "tenancy_ocid" {
  type        = string
  description = "OCI tenancy OCID used to query availability domains."
}

variable "compartment_id" {
  type        = string
  description = "OCI compartment OCID."
}

variable "private_subnet_id" {
  type        = string
  description = "Private subnet ID for instances."
}

variable "instance_count" {
  type        = number
  default     = 1
  description = "Number of instances to create."
}

variable "instance_shape" {
  type        = string
  default     = "VM.Standard.E4.Flex"
  description = "OCI instance shape."
}

variable "instance_shape_config" {
  type = object({
    ocpus         = number
    memory_in_gbs = number
  })
  default     = null
  description = "Optional flex shape configuration."
}

variable "image_id" {
  type        = string
  description = "OCI image OCID for the instance OS."
}

variable "ssh_public_key" {
  type        = string
  default     = ""
  description = "Optional SSH public key."
  sensitive   = true
}

variable "data_volume_enabled" {
  type        = bool
  default     = false
  description = "Whether to attach a block volume to each node."
}

variable "data_volume_size_gb" {
  type        = number
  default     = 100
  description = "Block volume size in GiB."
}

variable "data_volume_vpus_per_gb" {
  type        = number
  default     = 10
  description = "Performance level for OCI block storage."
}

variable "data_volume_prevent_destroy" {
  type        = bool
  default     = false
  description = "Whether Terraform should prevent block volume destroy."
}

variable "backup_policy_name" {
  type        = string
  default     = ""
  description = "OCI predefined backup policy display name, for example bronze, silver, or gold."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}

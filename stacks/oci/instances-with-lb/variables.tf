variable "name" {
  type        = string
  description = "Unique name for this deployment."
}

variable "region" {
  type        = string
  description = "OCI region."
}

variable "tenancy_ocid" {
  type        = string
  description = "OCI tenancy OCID."
}

variable "compartment_id" {
  type        = string
  description = "OCI compartment OCID."
}

variable "vcn_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VCN CIDR block."
}

variable "public_subnet_cidr" {
  type        = string
  default     = "10.0.0.0/24"
  description = "Public subnet CIDR."
}

variable "private_subnet_cidr" {
  type        = string
  default     = "10.0.10.0/24"
  description = "Private subnet CIDR."
}

variable "dns_label" {
  type        = string
  default     = "catalog"
  description = "DNS label for the VCN."
}

variable "instance_count" {
  type        = number
  default     = 1
  description = "Number of compute instances."
}

variable "instance_shape" {
  type        = string
  default     = "VM.Standard.E4.Flex"
  description = "OCI shape."
}

variable "instance_shape_config" {
  type = object({
    ocpus         = number
    memory_in_gbs = number
  })
  default     = null
  description = "Optional flex shape sizing."
}

variable "image_id" {
  type        = string
  description = "OCI image OCID."
}

variable "ssh_public_key" {
  type        = string
  default     = ""
  description = "Optional SSH public key."
  sensitive   = true
}

variable "allowed_cidrs_admin" {
  type        = list(string)
  default     = []
  description = "Administrative CIDRs."
}

variable "allowed_cidrs_app" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDRs allowed to reach public application listeners."
}

variable "data_volume_enabled" {
  type        = bool
  default     = false
  description = "Whether to attach block volumes to nodes."
}

variable "data_volume_size_gb" {
  type        = number
  default     = 100
  description = "Block volume size in GiB."
}

variable "data_volume_vpus_per_gb" {
  type        = number
  default     = 10
  description = "Block volume performance setting."
}

variable "data_volume_prevent_destroy" {
  type        = bool
  default     = false
  description = "Whether Terraform should prevent block volume destroy."
}

variable "backup_policy_name" {
  type        = string
  default     = ""
  description = "OCI predefined backup policy name, for example bronze, silver, or gold."
}

variable "lb_min_bandwidth_mbps" {
  type        = number
  default     = 10
  description = "Minimum OCI load balancer bandwidth."
}

variable "lb_max_bandwidth_mbps" {
  type        = number
  default     = 100
  description = "Maximum OCI load balancer bandwidth."
}

variable "app_ports" {
  type = list(object({
    port              = number
    name              = string
    health_check_path = optional(string, "/health")
  }))
  description = "Application ports exposed through the OCI load balancer."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}

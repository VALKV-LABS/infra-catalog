variable "name_prefix" {
  type        = string
  description = "Prefix applied to resource names."
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
  description = "Public subnet CIDR block."
}

variable "private_subnet_cidr" {
  type        = string
  default     = "10.0.10.0/24"
  description = "Private subnet CIDR block."
}

variable "dns_label" {
  type        = string
  default     = "catalog"
  description = "DNS label for the VCN."
}

variable "app_ports" {
  type = list(object({
    port              = number
    name              = string
    health_check_path = optional(string, "/health")
  }))
  description = "Application ports exposed through the load balancer."
}

variable "allowed_app_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDRs allowed to access public application listeners."
}

variable "admin_cidrs" {
  type        = list(string)
  default     = []
  description = "Administrative CIDRs. OCI stack currently expects bastion or private access for SSH."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}

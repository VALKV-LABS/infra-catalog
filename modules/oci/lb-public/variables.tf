variable "name_prefix" {
  type        = string
  description = "Prefix applied to resource names."
}

variable "compartment_id" {
  type        = string
  description = "OCI compartment OCID."
}

variable "public_subnet_id" {
  type        = string
  description = "Public subnet ID for the load balancer."
}

variable "instances" {
  type = map(object({
    private_ip = string
  }))
  description = "Instances keyed by node name."
}

variable "app_ports" {
  type = list(object({
    port              = number
    name              = string
    health_check_path = optional(string, "/health")
  }))
  description = "Application ports exposed through the load balancer."
}

variable "min_bandwidth_mbps" {
  type        = number
  default     = 10
  description = "Minimum OCI load balancer bandwidth."
}

variable "max_bandwidth_mbps" {
  type        = number
  default     = 100
  description = "Maximum OCI load balancer bandwidth."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}

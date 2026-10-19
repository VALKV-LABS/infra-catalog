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
  description = "Public subnet ID for the network load balancer."
}

variable "instances" {
  type = map(object({
    private_ip = string
  }))
  description = "Instances keyed by node name."
}

variable "listener_port" {
  type        = number
  default     = 443
  description = "Public listener port on the OCI NLB."
}

variable "listener_protocol" {
  type        = string
  default     = "TCP"
  description = "Listener protocol for the OCI NLB."
}

variable "target_port" {
  type        = number
  default     = 443
  description = "Port on the instances that receives NLB traffic."
}

variable "health_check_protocol" {
  type        = string
  default     = "TCP"
  description = "Health check protocol."
}

variable "health_check_port" {
  type        = number
  default     = 443
  description = "Health check port on the instances."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}

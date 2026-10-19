variable "name_prefix" {
  type        = string
  description = "Prefix applied to resource names."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID hosting the ALB."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the ALB."
}

variable "app_ports" {
  type = list(object({
    port              = number
    name              = string
    health_check_path = optional(string, "/health")
  }))
  description = "Service ports to expose through the load balancer."
}

variable "ingress_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDRs allowed to access the load balancer."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}

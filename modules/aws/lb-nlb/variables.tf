variable "name_prefix" {
  type        = string
  description = "Prefix applied to resource names."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID hosting the NLB."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the NLB."
}

variable "listener_port" {
  type        = number
  default     = 443
  description = "Public listener port on the NLB."
}

variable "listener_protocol" {
  type        = string
  default     = "TCP"
  description = "Listener protocol for the NLB."
}

variable "target_port" {
  type        = number
  default     = 443
  description = "Port on the instances that receives NLB traffic."
}

variable "target_protocol" {
  type        = string
  default     = "TCP"
  description = "Target group protocol."
}

variable "health_check_protocol" {
  type        = string
  default     = "TCP"
  description = "Health check protocol."
}

variable "health_check_port" {
  type        = string
  default     = "traffic-port"
  description = "Health check port. For an instance target this is the port ON THE HOST, so it must match what the container publishes, not what it listens on inside."
}

variable "health_check_path" {
  type        = string
  default     = ""
  description = <<-EOT
    Path for an HTTP/HTTPS health check. Ignored for TCP.

    Leaving this empty with health_check_protocol = "HTTP" makes AWS default to
    "/", which fails against any target that does not serve that exact path —
    the check then never passes and the target group has no healthy members.
    Always set it explicitly alongside an HTTP protocol.
  EOT
}

variable "ingress_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDRs allowed to access the NLB listener."
}

# Additional listener/target-group pairs beyond the primary one above — e.g. a
# proxy tier that needs both 443 (TLS passthrough) and 80 (ACME HTTP-01
# challenge response) forwarded to the same instances. Each entry gets its
# own target group and listener; instances must be attached to
# extra_target_group_arns by the caller the same way they attach to the
# primary target_group_arn output.
variable "extra_listeners" {
  type = list(object({
    name                  = string
    listener_port         = number
    listener_protocol     = optional(string, "TCP")
    target_port           = number
    target_protocol       = optional(string, "TCP")
    health_check_protocol = optional(string, "TCP")
    health_check_port     = optional(string, "traffic-port")
    health_check_path     = optional(string, "")
  }))
  default     = []
  description = "Additional listener/target-group pairs, e.g. a plain-HTTP:80 listener alongside the primary TLS:443 one. health_check_path is required alongside an HTTP protocol — see the top-level health_check_path for why."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}

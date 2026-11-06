variable "name_prefix" {
  type        = string
  description = "Prefix applied to resource names."
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for the VPC."
}

variable "az_count" {
  type        = number
  default     = 2
  description = "Number of availability zones."

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "az_count must be between 1 and 3."
  }
}

variable "nat_gateway_enabled" {
  type        = bool
  default     = true
  description = "Create NAT gateways for private subnet egress. When false, private subnets have no route to the internet: instances that need egress must run in the public subnets with public IPs, or reach AWS services through VPC endpoints."
}

variable "single_nat" {
  type        = bool
  default     = true
  description = "Whether to use a single shared NAT gateway. Ignored when nat_gateway_enabled is false."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}

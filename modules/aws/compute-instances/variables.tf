variable "name_prefix" {
  type        = string
  description = "Prefix applied to resource names."
}

variable "aws_region" {
  type        = string
  description = "AWS region for userdata rendering."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where instances are created."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs used for round-robin placement."
}

variable "lb_security_group_id" {
  type        = string
  description = "Load balancer security group ID allowed to reach app ports."
}

variable "node_count" {
  type        = number
  default     = 1
  description = "Number of instances to create."
}

variable "instance_type" {
  type        = string
  default     = "t4g.micro"
  description = "EC2 instance type."
}

variable "root_volume_gb" {
  type        = number
  default     = 20
  description = "Root EBS volume size in GiB."
}

variable "data_volume_gb" {
  type        = number
  default     = 0
  description = "Optional attached data volume size in GiB. Set to 0 to disable."
}

variable "data_volume_prevent_destroy" {
  type        = bool
  default     = false
  description = "Whether Terraform should prevent destroying attached data volumes."
}

variable "backup_policy_enabled" {
  type        = bool
  default     = false
  description = "Whether attached data volumes should be tagged for a backup policy."
}

variable "backup_policy_name" {
  type        = string
  default     = "daily"
  description = "Label used on EBS volumes to match a backup policy."
}

variable "app_ports" {
  type = list(object({
    port              = number
    name              = string
    health_check_path = optional(string, "/health")
  }))
  description = "Application ports exposed through the load balancer."
}

variable "admin_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDRs permitted to SSH to the instances."
}

variable "ssh_public_key" {
  type        = string
  default     = ""
  description = "Optional SSH public key for break-glass access."
  sensitive   = true
}

variable "ami_id" {
  type        = string
  default     = ""
  description = "Optional explicit AMI ID."
}

variable "os_family" {
  type        = string
  default     = "amazon_linux"
  description = "Operating system family of ami_id. Selects compatible instance bootstrap user data."

  validation {
    condition     = contains(["amazon_linux", "ubuntu"], var.os_family)
    error_message = "os_family must be either amazon_linux or ubuntu."
  }
}

variable "ssm_parameter_path_prefixes" {
  type        = list(string)
  default     = ["/valkv/"]
  description = "SSM parameter path prefixes the instance role can read."
}

variable "ecr_read_only_enabled" {
  type        = bool
  default     = true
  description = "Whether to attach AmazonEC2ContainerRegistryReadOnly so instances can pull from ECR using the instance profile."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}

variable "extra_policy_arns" {
  type        = list(string)
  default     = []
  description = <<-EOT
    Additional IAM policies to attach to these nodes' role.

    A generic hook on purpose: this module is shared by the proxy tier, the app
    tier and others, so anything one tier needs and the rest do not belongs here
    rather than in the module's own policy document. The app tier uses it to grant
    global-cp the narrow IAM rights it needs to manage per-project BaaS storage
    roles.
  EOT
}

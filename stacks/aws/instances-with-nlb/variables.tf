variable "name" {
  type        = string
  description = "Unique name for this deployment."
}

variable "region" {
  type        = string
  description = "AWS region to deploy into."
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
}

variable "single_nat" {
  type        = bool
  default     = true
  description = "Whether to use a single NAT gateway."
}

variable "instance_count" {
  type        = number
  default     = 1
  description = "Number of compute instances."
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

variable "data_volume_enabled" {
  type        = bool
  default     = false
  description = "Whether to attach an additional EBS volume to each node."
}

variable "data_volume_size_gb" {
  type        = number
  default     = 100
  description = "Size in GiB of the attached data volume."
}

variable "data_volume_prevent_destroy" {
  type        = bool
  default     = false
  description = "Whether Terraform should prevent destroy for attached data volumes."
}

variable "backup_policy_enabled" {
  type        = bool
  default     = false
  description = "Whether to create an EBS snapshot backup policy."
}

variable "backup_policy_name" {
  type        = string
  default     = "daily"
  description = "Logical backup policy label."
}

variable "snapshot_interval" {
  type        = number
  default     = 24
  description = "Snapshot interval."
}

variable "snapshot_interval_unit" {
  type        = string
  default     = "HOURS"
  description = "Snapshot interval unit."
}

variable "snapshot_time_utc" {
  type        = string
  default     = "03:00"
  description = "UTC time for snapshots."
}

variable "snapshot_retention_count" {
  type        = number
  default     = 7
  description = "Number of snapshots to retain."
}

variable "snapshot_copy_to_region" {
  type        = string
  default     = ""
  description = "Optional secondary region for snapshot copies."
}

variable "snapshot_copy_retention_days" {
  type        = number
  default     = 7
  description = "Retention for copied snapshots."
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
  description = "CIDRs allowed SSH access."
}

variable "allowed_cidrs_app" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDRs allowed to reach the NLB listener."
}

variable "ami_id" {
  type        = string
  default     = ""
  description = "Optional explicit AMI ID."
}

variable "ssm_parameter_path_prefixes" {
  type        = list(string)
  default     = ["/valkv/"]
  description = "SSM parameter path prefixes readable by the instance role."
}

variable "ecr_read_only_enabled" {
  type        = bool
  default     = true
  description = "Whether instances can pull from ECR using the instance profile."
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
  description = "Health check port. For instance targets this is the port on the HOST, which is not necessarily the port the container listens on inside."
}

variable "health_check_path" {
  type        = string
  default     = ""
  description = "Path for an HTTP/HTTPS health check. Required alongside an HTTP protocol: left empty, AWS defaults to \"/\" and the check fails against anything that does not serve that path, leaving the target group with no healthy members."
}

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
  description = "Additional listener/target-group pairs beyond the primary one, forwarded to the same instances (e.g. a plain-HTTP:80 listener alongside TLS:443 for ACME HTTP-01)."
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
    Additional IAM policies for these nodes' role, passed straight to
    compute-instances.

    Dev uses it the way prod-globalcp-us-east-1 does: global-cp runs on this host
    and needs narrow rights over the per-project BaaS storage roles it creates.
  EOT
}

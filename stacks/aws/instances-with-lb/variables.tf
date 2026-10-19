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
  description = "CIDRs allowed to reach app listeners."
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

variable "app_ports" {
  type = list(object({
    port              = number
    name              = string
    health_check_path = optional(string, "/health")
  }))
  description = "Application ports exposed through the ALB."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}

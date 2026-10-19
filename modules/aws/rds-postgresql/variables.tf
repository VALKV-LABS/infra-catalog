variable "name_prefix" {
  type        = string
  description = "Prefix applied to resource names."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the database security group."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs used by the DB subnet group."
}

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "Security groups allowed to connect to PostgreSQL."
}

variable "db_name" {
  type        = string
  default     = "app"
  description = "Initial PostgreSQL database name."
}

variable "admin_username" {
  type        = string
  default     = "postgresadmin"
  description = "Initial PostgreSQL admin username."
}

variable "instance_class" {
  type        = string
  default     = "db.t4g.micro"
  description = "RDS instance class, for example db.t4g.micro."
}

variable "engine_version" {
  type        = string
  default     = "16.3"
  description = "PostgreSQL engine version."
}

variable "allocated_storage" {
  type        = number
  default     = 20
  description = "Allocated storage in GiB."
}

variable "max_allocated_storage" {
  type        = number
  default     = 100
  description = "Maximum autoscaled storage in GiB."
}

variable "storage_type" {
  type        = string
  default     = "gp3"
  description = "RDS storage type."
}

variable "port" {
  type        = number
  default     = 5432
  description = "PostgreSQL port."
}

variable "multi_az" {
  type        = bool
  default     = false
  description = "Whether to use Multi-AZ deployment."
}

variable "backup_retention_period" {
  type        = number
  default     = 7
  description = "Automatic backup retention in days."
}

variable "backup_window" {
  type        = string
  default     = "03:00-04:00"
  description = "Preferred backup window in UTC."
}

variable "maintenance_window" {
  type        = string
  default     = "sun:04:00-sun:05:00"
  description = "Preferred maintenance window in UTC."
}

variable "auto_minor_version_upgrade" {
  type        = bool
  default     = true
  description = "Whether to allow minor version upgrades."
}

variable "deletion_protection" {
  type        = bool
  default     = true
  description = "Whether to enable deletion protection."
}

variable "skip_final_snapshot" {
  type        = bool
  default     = false
  description = "Whether to skip the final snapshot on destroy."
}

variable "apply_immediately" {
  type        = bool
  default     = false
  description = "Whether to apply DB modifications immediately."
}

variable "performance_insights_enabled" {
  type        = bool
  default     = true
  description = "Whether to enable Performance Insights."
}

variable "performance_insights_retention_period" {
  type        = number
  default     = 7
  description = "Performance Insights retention period in days."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}

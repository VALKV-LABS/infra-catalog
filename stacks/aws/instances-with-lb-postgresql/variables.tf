variable "name" { type = string description = "Unique name for this deployment." }
variable "region" { type = string description = "AWS region to deploy into." }
variable "vpc_cidr" { type = string default = "10.0.0.0/16" description = "CIDR block for the VPC." }
variable "az_count" { type = number default = 2 description = "Number of availability zones." }
variable "single_nat" { type = bool default = true description = "Whether to use a single NAT gateway." }
variable "instance_count" { type = number default = 1 description = "Number of compute instances." }
variable "instance_type" { type = string default = "t4g.micro" description = "EC2 instance type." }
variable "root_volume_gb" { type = number default = 20 description = "Root EBS volume size in GiB." }
variable "data_volume_enabled" { type = bool default = false description = "Whether to attach an additional EBS volume to each node." }
variable "data_volume_size_gb" { type = number default = 100 description = "Size in GiB of the attached data volume." }
variable "data_volume_prevent_destroy" { type = bool default = false description = "Whether Terraform should prevent destroy for attached data volumes." }
variable "backup_policy_enabled" { type = bool default = false description = "Whether to create an EBS snapshot backup policy." }
variable "backup_policy_name" { type = string default = "daily" description = "Logical backup policy label." }
variable "snapshot_interval" { type = number default = 24 description = "Snapshot interval." }
variable "snapshot_interval_unit" { type = string default = "HOURS" description = "Snapshot interval unit." }
variable "snapshot_time_utc" { type = string default = "03:00" description = "UTC time for snapshots." }
variable "snapshot_retention_count" { type = number default = 7 description = "Number of snapshots to retain." }
variable "snapshot_copy_to_region" { type = string default = "" description = "Optional secondary region for snapshot copies." }
variable "snapshot_copy_retention_days" { type = number default = 7 description = "Retention for copied snapshots." }
variable "ssh_public_key" { type = string default = "" description = "Optional SSH public key." sensitive = true }
variable "allowed_cidrs_admin" { type = list(string) default = [] description = "CIDRs allowed SSH access." }
variable "allowed_cidrs_app" { type = list(string) default = ["0.0.0.0/0"] description = "CIDRs allowed to reach app listeners." }
variable "ami_id" { type = string default = "" description = "Optional explicit AMI ID." }
variable "ssm_parameter_path_prefixes" { type = list(string) default = ["/valkv/"] description = "SSM parameter path prefixes readable by the instance role." }
variable "ecr_read_only_enabled" { type = bool default = true description = "Whether instances can pull from ECR using the instance profile." }
variable "app_ports" {
  type = list(object({
    port              = number
    name              = string
    health_check_path = optional(string, "/health")
  }))
  description = "Application ports exposed through the ALB."
}
variable "postgresql_db_name" { type = string default = "app" description = "Initial PostgreSQL database name." }
variable "postgresql_admin_username" { type = string default = "postgresadmin" description = "Initial PostgreSQL admin username." }
variable "postgresql_instance_class" { type = string default = "db.t4g.micro" description = "RDS instance class, for example db.t4g.micro." }
variable "postgresql_engine_version" { type = string default = "16.3" description = "PostgreSQL engine version." }
variable "postgresql_allocated_storage" { type = number default = 20 description = "Allocated PostgreSQL storage in GiB." }
variable "postgresql_max_allocated_storage" { type = number default = 100 description = "Maximum autoscaled PostgreSQL storage in GiB." }
variable "postgresql_storage_type" { type = string default = "gp3" description = "RDS storage type." }
variable "postgresql_port" { type = number default = 5432 description = "PostgreSQL port." }
variable "postgresql_multi_az" { type = bool default = false description = "Whether to use Multi-AZ deployment." }
variable "postgresql_backup_retention_period" { type = number default = 7 description = "Automatic backup retention in days." }
variable "postgresql_backup_window" { type = string default = "03:00-04:00" description = "Preferred backup window in UTC." }
variable "postgresql_maintenance_window" { type = string default = "sun:04:00-sun:05:00" description = "Preferred maintenance window in UTC." }
variable "postgresql_auto_minor_version_upgrade" { type = bool default = true description = "Whether to allow minor version upgrades." }
variable "postgresql_deletion_protection" { type = bool default = true description = "Whether to enable deletion protection." }
variable "postgresql_skip_final_snapshot" { type = bool default = false description = "Whether to skip the final snapshot on destroy." }
variable "postgresql_apply_immediately" { type = bool default = false description = "Whether to apply DB modifications immediately." }
variable "postgresql_performance_insights_enabled" { type = bool default = true description = "Whether to enable Performance Insights." }
variable "postgresql_performance_insights_retention_period" { type = number default = 7 description = "Performance Insights retention period in days." }
variable "tags" { type = map(string) default = {} description = "Tags applied to all resources." }

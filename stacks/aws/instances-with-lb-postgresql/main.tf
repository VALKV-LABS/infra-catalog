module "app" {
  source = "../instances-with-lb"

  name                         = var.name
  region                       = var.region
  vpc_cidr                     = var.vpc_cidr
  az_count                     = var.az_count
  single_nat                   = var.single_nat
  instance_count               = var.instance_count
  instance_type                = var.instance_type
  root_volume_gb               = var.root_volume_gb
  data_volume_enabled          = var.data_volume_enabled
  data_volume_size_gb          = var.data_volume_size_gb
  data_volume_prevent_destroy  = var.data_volume_prevent_destroy
  backup_policy_enabled        = var.backup_policy_enabled
  backup_policy_name           = var.backup_policy_name
  snapshot_interval            = var.snapshot_interval
  snapshot_interval_unit       = var.snapshot_interval_unit
  snapshot_time_utc            = var.snapshot_time_utc
  snapshot_retention_count     = var.snapshot_retention_count
  snapshot_copy_to_region      = var.snapshot_copy_to_region
  snapshot_copy_retention_days = var.snapshot_copy_retention_days
  ssh_public_key               = var.ssh_public_key
  allowed_cidrs_admin          = var.allowed_cidrs_admin
  allowed_cidrs_app            = var.allowed_cidrs_app
  ami_id                       = var.ami_id
  ssm_parameter_path_prefixes  = var.ssm_parameter_path_prefixes
  ecr_read_only_enabled        = var.ecr_read_only_enabled
  app_ports                    = var.app_ports
  tags                         = local.tags
}

module "postgresql" {
  source = "../../../modules/aws/rds-postgresql"

  name_prefix                          = var.name
  vpc_id                               = module.app.vpc_id
  subnet_ids                           = module.app.private_subnet_ids
  allowed_security_group_ids           = [module.app.instance_security_group_id]
  db_name                              = var.postgresql_db_name
  admin_username                       = var.postgresql_admin_username
  instance_class                       = var.postgresql_instance_class
  engine_version                       = var.postgresql_engine_version
  allocated_storage                    = var.postgresql_allocated_storage
  max_allocated_storage                = var.postgresql_max_allocated_storage
  storage_type                         = var.postgresql_storage_type
  port                                 = var.postgresql_port
  multi_az                             = var.postgresql_multi_az
  backup_retention_period              = var.postgresql_backup_retention_period
  backup_window                        = var.postgresql_backup_window
  maintenance_window                   = var.postgresql_maintenance_window
  auto_minor_version_upgrade           = var.postgresql_auto_minor_version_upgrade
  deletion_protection                  = var.postgresql_deletion_protection
  skip_final_snapshot                  = var.postgresql_skip_final_snapshot
  apply_immediately                    = var.postgresql_apply_immediately
  performance_insights_enabled         = var.postgresql_performance_insights_enabled
  performance_insights_retention_period = var.postgresql_performance_insights_retention_period
  tags                                 = local.tags
}

locals {
  tags = merge(var.tags, {
    CatalogStack = "aws/instances-with-lb-postgresql"
  })
}

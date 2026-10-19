module "app" {
  source = "../instances-with-lb"

  name                       = var.name
  region                     = var.region
  tenancy_ocid               = var.tenancy_ocid
  compartment_id             = var.compartment_id
  vcn_cidr                   = var.vcn_cidr
  public_subnet_cidr         = var.public_subnet_cidr
  private_subnet_cidr        = var.private_subnet_cidr
  dns_label                  = var.dns_label
  instance_count             = var.instance_count
  instance_shape             = var.instance_shape
  instance_shape_config      = var.instance_shape_config
  image_id                   = var.image_id
  ssh_public_key             = var.ssh_public_key
  allowed_cidrs_admin        = var.allowed_cidrs_admin
  allowed_cidrs_app          = var.allowed_cidrs_app
  data_volume_enabled        = var.data_volume_enabled
  data_volume_size_gb        = var.data_volume_size_gb
  data_volume_vpus_per_gb    = var.data_volume_vpus_per_gb
  data_volume_prevent_destroy = var.data_volume_prevent_destroy
  backup_policy_name         = var.backup_policy_name
  lb_min_bandwidth_mbps      = var.lb_min_bandwidth_mbps
  lb_max_bandwidth_mbps      = var.lb_max_bandwidth_mbps
  app_ports                  = var.app_ports
  tags                       = local.tags
}

module "postgresql" {
  source = "../../../modules/oci/managed-postgresql"

  name_prefix                    = var.name
  compartment_id                 = var.compartment_id
  subnet_id                      = module.app.private_subnet_id
  db_version                     = var.postgresql_db_version
  shape                          = var.postgresql_shape
  instance_count                 = var.postgresql_instance_count
  instance_ocpu_count            = var.postgresql_instance_ocpu_count
  instance_memory_size_in_gbs    = var.postgresql_instance_memory_size_in_gbs
  admin_username                 = var.postgresql_admin_username
  password_type                  = var.postgresql_password_type
  admin_password                 = var.postgresql_admin_password
  admin_password_secret_id       = var.postgresql_admin_password_secret_id
  admin_password_secret_version  = var.postgresql_admin_password_secret_version
  storage_is_regionally_durable  = var.postgresql_storage_is_regionally_durable
  storage_system_type            = var.postgresql_storage_system_type
  storage_iops                   = var.postgresql_storage_iops
  description                    = var.postgresql_description
  tags                           = local.tags
}

locals {
  tags = merge(var.tags, {
    CatalogStack = "oci/instances-with-lb-postgresql"
  })
}

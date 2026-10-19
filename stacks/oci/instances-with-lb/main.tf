module "network" {
  source = "../../../modules/oci/network-vcn"

  name_prefix         = var.name
  compartment_id      = var.compartment_id
  vcn_cidr            = var.vcn_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  dns_label           = var.dns_label
  app_ports           = var.app_ports
  allowed_app_cidrs   = var.allowed_cidrs_app
  admin_cidrs         = var.allowed_cidrs_admin
  tags                = local.tags
}

module "compute" {
  source = "../../../modules/oci/compute-instances"

  name_prefix                 = var.name
  tenancy_ocid                = var.tenancy_ocid
  compartment_id              = var.compartment_id
  private_subnet_id           = module.network.private_subnet_id
  instance_count              = var.instance_count
  instance_shape              = var.instance_shape
  instance_shape_config       = var.instance_shape_config
  image_id                    = var.image_id
  ssh_public_key              = var.ssh_public_key
  data_volume_enabled         = var.data_volume_enabled
  data_volume_size_gb         = var.data_volume_size_gb
  data_volume_vpus_per_gb     = var.data_volume_vpus_per_gb
  data_volume_prevent_destroy = var.data_volume_prevent_destroy
  backup_policy_name          = var.backup_policy_name
  tags                        = local.tags
}

module "lb" {
  source = "../../../modules/oci/lb-public"

  name_prefix        = var.name
  compartment_id     = var.compartment_id
  public_subnet_id   = module.network.public_subnet_id
  instances          = module.compute.instances
  app_ports          = var.app_ports
  min_bandwidth_mbps = var.lb_min_bandwidth_mbps
  max_bandwidth_mbps = var.lb_max_bandwidth_mbps
  tags               = local.tags
}

locals {
  tags = merge(var.tags, {
    CatalogStack = "oci/instances-with-lb"
  })
}

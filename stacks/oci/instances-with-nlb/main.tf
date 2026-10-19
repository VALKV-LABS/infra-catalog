module "network" {
  source = "../../../modules/oci/network-vcn"

  name_prefix         = var.name
  compartment_id      = var.compartment_id
  vcn_cidr            = var.vcn_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  dns_label           = var.dns_label
  app_ports = [
    {
      port = var.listener_port
      name = "nlb-listener"
    }
  ]
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

module "nlb" {
  source = "../../../modules/oci/nlb-public"

  name_prefix           = var.name
  compartment_id        = var.compartment_id
  public_subnet_id      = module.network.public_subnet_id
  instances             = module.compute.instances
  listener_port         = var.listener_port
  listener_protocol     = var.listener_protocol
  target_port           = var.target_port
  health_check_protocol = var.health_check_protocol
  health_check_port     = var.health_check_port
  tags                  = local.tags
}

locals {
  tags = merge(var.tags, {
    CatalogStack = "oci/instances-with-nlb"
  })
}

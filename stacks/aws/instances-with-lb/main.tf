module "network" {
  source = "../../../modules/aws/network-vpc"

  name_prefix = var.name
  vpc_cidr    = var.vpc_cidr
  az_count    = var.az_count
  single_nat  = var.single_nat
  tags        = local.tags
}

module "lb" {
  source = "../../../modules/aws/lb-alb"

  name_prefix   = var.name
  vpc_id        = module.network.vpc_id
  subnet_ids    = module.network.public_subnet_ids
  app_ports     = var.app_ports
  ingress_cidrs = var.allowed_cidrs_app
  tags          = local.tags
}

module "compute" {
  source = "../../../modules/aws/compute-instances"

  name_prefix                 = var.name
  aws_region                  = var.region
  vpc_id                      = module.network.vpc_id
  private_subnet_ids          = module.network.private_subnet_ids
  lb_security_group_id        = module.lb.security_group_id
  node_count                  = var.instance_count
  instance_type               = var.instance_type
  root_volume_gb              = var.root_volume_gb
  data_volume_gb              = var.data_volume_enabled ? var.data_volume_size_gb : 0
  data_volume_prevent_destroy = var.data_volume_prevent_destroy
  backup_policy_enabled       = var.backup_policy_enabled
  backup_policy_name          = var.backup_policy_name
  app_ports                   = var.app_ports
  admin_cidrs                 = var.allowed_cidrs_admin
  ssh_public_key              = var.ssh_public_key
  ami_id                      = var.ami_id
  ssm_parameter_path_prefixes = var.ssm_parameter_path_prefixes
  ecr_read_only_enabled       = var.ecr_read_only_enabled
  tags                        = local.tags
}

module "backup_policy" {
  count  = var.data_volume_enabled && var.backup_policy_enabled ? 1 : 0
  source = "../../../modules/aws/ebs-backup-policy"

  name_prefix            = var.name
  stack_name             = var.name
  backup_policy_name     = var.backup_policy_name
  snapshot_interval      = var.snapshot_interval
  snapshot_interval_unit = var.snapshot_interval_unit
  snapshot_time_utc      = var.snapshot_time_utc
  retention_count        = var.snapshot_retention_count
  copy_to_region         = var.snapshot_copy_to_region
  copy_retention_interval = var.snapshot_copy_retention_days
  tags                   = local.tags
}

locals {
  target_group_attachments = {
    for pair in flatten([
      for instance_index, instance_id in module.compute.instance_ids : [
        for port_str, tg_arn in module.lb.target_group_arns : {
          key         = "${instance_index}-${port_str}"
          tg_arn      = tg_arn
          instance_id = instance_id
          port        = tonumber(port_str)
        }
      ]
    ]) : pair.key => pair
  }

  tags = merge(var.tags, {
    CatalogStack = "aws/instances-with-lb"
  })
}

resource "aws_lb_target_group_attachment" "nodes" {
  for_each = local.target_group_attachments

  target_group_arn = each.value.tg_arn
  target_id        = each.value.instance_id
  port             = each.value.port
}

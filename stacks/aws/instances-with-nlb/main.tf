module "network" {
  source = "../../../modules/aws/network-vpc"

  name_prefix = var.name
  vpc_cidr    = var.vpc_cidr
  az_count    = var.az_count
  single_nat  = var.single_nat
  tags        = local.tags
}

module "nlb" {
  source = "../../../modules/aws/lb-nlb"

  name_prefix           = var.name
  vpc_id                = module.network.vpc_id
  subnet_ids            = module.network.public_subnet_ids
  listener_port         = var.listener_port
  listener_protocol     = var.listener_protocol
  target_port           = var.target_port
  target_protocol       = var.target_protocol
  health_check_protocol = var.health_check_protocol
  health_check_port     = var.health_check_port
  health_check_path     = var.health_check_path
  ingress_cidrs         = var.allowed_cidrs_app
  extra_listeners       = var.extra_listeners
  tags                  = local.tags
}

module "compute" {
  source = "../../../modules/aws/compute-instances"

  name_prefix                 = var.name
  aws_region                  = var.region
  vpc_id                      = module.network.vpc_id
  private_subnet_ids          = module.network.private_subnet_ids
  lb_security_group_id        = module.nlb.security_group_id
  node_count                  = var.instance_count
  instance_type               = var.instance_type
  root_volume_gb              = var.root_volume_gb
  data_volume_gb              = var.data_volume_enabled ? var.data_volume_size_gb : 0
  data_volume_prevent_destroy = var.data_volume_prevent_destroy
  backup_policy_enabled       = var.backup_policy_enabled
  backup_policy_name          = var.backup_policy_name
  app_ports = concat(
    [{ port = var.target_port, name = "nlb-target" }],
    [for l in var.extra_listeners : { port = l.target_port, name = "nlb-${l.name}" }]
  )
  admin_cidrs                 = var.allowed_cidrs_admin
  ssh_public_key              = var.ssh_public_key
  ami_id                      = var.ami_id
  ssm_parameter_path_prefixes = var.ssm_parameter_path_prefixes
  extra_policy_arns           = var.extra_policy_arns
  ecr_read_only_enabled       = var.ecr_read_only_enabled
  tags                        = local.tags
}

module "backup_policy" {
  count  = var.data_volume_enabled && var.backup_policy_enabled ? 1 : 0
  source = "../../../modules/aws/ebs-backup-policy"

  name_prefix             = var.name
  stack_name              = var.name
  backup_policy_name      = var.backup_policy_name
  snapshot_interval       = var.snapshot_interval
  snapshot_interval_unit  = var.snapshot_interval_unit
  snapshot_time_utc       = var.snapshot_time_utc
  retention_count         = var.snapshot_retention_count
  copy_to_region          = var.snapshot_copy_to_region
  copy_retention_interval = var.snapshot_copy_retention_days
  tags                    = local.tags
}

locals {
  tags = merge(var.tags, {
    CatalogStack = "aws/instances-with-nlb"
  })
}

resource "aws_lb_target_group_attachment" "nodes" {
  for_each = {
    for index, instance_id in module.compute.instance_ids : tostring(index) => instance_id
  }

  target_group_arn = module.nlb.target_group_arn
  target_id        = each.value
  port             = var.target_port
}

resource "aws_lb_target_group_attachment" "nodes_extra" {
  for_each = {
    for pair in setproduct(range(length(module.compute.instance_ids)), var.extra_listeners) :
    "${pair[0]}-${pair[1].name}" => pair
  }

  target_group_arn = module.nlb.extra_target_group_arns[each.value[1].name]
  target_id        = module.compute.instance_ids[each.value[0]]
  port             = each.value[1].target_port
}

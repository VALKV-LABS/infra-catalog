resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-postgres"
  subnet_ids = var.subnet_ids
  tags       = merge(var.tags, { Name = "${var.name_prefix}-postgres-subnets" })
}

resource "aws_security_group" "db" {
  name        = "${var.name_prefix}-postgres-sg"
  description = "Managed PostgreSQL for ${var.name_prefix}"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name_prefix}-postgres-sg" })
}

resource "aws_security_group_rule" "db_from_apps" {
  for_each = toset(var.allowed_security_group_ids)

  type                     = "ingress"
  security_group_id        = aws_security_group.db.id
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = each.value
  description              = "Application instances to PostgreSQL"
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  security_group_id = aws_security_group.db.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_db_instance" "this" {
  identifier                     = substr("${var.name_prefix}-postgres", 0, 63)
  engine                         = "postgres"
  engine_version                 = var.engine_version
  instance_class                 = var.instance_class
  db_name                        = var.db_name
  username                       = var.admin_username
  manage_master_user_password    = true
  allocated_storage              = var.allocated_storage
  max_allocated_storage          = var.max_allocated_storage
  storage_type                   = var.storage_type
  storage_encrypted              = true
  port                           = var.port
  db_subnet_group_name           = aws_db_subnet_group.this.name
  vpc_security_group_ids         = [aws_security_group.db.id]
  publicly_accessible            = false
  multi_az                       = var.multi_az
  backup_retention_period        = var.backup_retention_period
  backup_window                  = var.backup_window
  maintenance_window             = var.maintenance_window
  auto_minor_version_upgrade     = var.auto_minor_version_upgrade
  deletion_protection            = var.deletion_protection
  skip_final_snapshot            = var.skip_final_snapshot
  final_snapshot_identifier      = var.skip_final_snapshot ? null : "${substr(var.name_prefix, 0, 40)}-postgres-final"
  copy_tags_to_snapshot          = true
  apply_immediately              = var.apply_immediately
  performance_insights_enabled   = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-postgres"
  })
}

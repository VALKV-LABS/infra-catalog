data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dlm" {
  name               = "${var.name_prefix}-dlm-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = merge(var.tags, { Name = "${var.name_prefix}-dlm-role" })
}

resource "aws_iam_role_policy_attachment" "dlm_service" {
  role       = aws_iam_role.dlm.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}

resource "aws_dlm_lifecycle_policy" "data_volume" {
  description        = "Snapshot policy for ${var.name_prefix} attached data volumes"
  execution_role_arn = aws_iam_role.dlm.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]
    target_tags = {
      Backup = var.backup_policy_name
      Stack  = var.stack_name
    }

    schedule {
      name = "${var.name_prefix}-${var.backup_policy_name}"
      copy_tags = true

      create_rule {
        interval      = var.snapshot_interval
        interval_unit = var.snapshot_interval_unit
        times         = [var.snapshot_time_utc]
      }

      retain_rule {
        count = var.retention_count
      }

      dynamic "cross_region_copy_rule" {
        for_each = var.copy_to_region != "" ? [var.copy_to_region] : []
        content {
          target    = cross_region_copy_rule.value
          encrypted = true

          retain_rule {
            interval      = var.copy_retention_interval
            interval_unit = "DAYS"
          }
        }
      }
    }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-dlm-policy" })
}

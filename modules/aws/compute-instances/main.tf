data "aws_ami" "al2023_arm64" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "node_permissions" {
  statement {
    sid = "SsmParams"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = [for path in var.ssm_parameter_path_prefixes : "arn:aws:ssm:*:*:parameter${path}*"]
  }

  statement {
    sid = "CwLogs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role" "node" {
  name               = "${var.name_prefix}-node-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = merge(var.tags, { Name = "${var.name_prefix}-node-role" })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  count = var.ecr_read_only_enabled ? 1 : 0

  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "node_permissions" {
  name   = "${var.name_prefix}-node-permissions"
  role   = aws_iam_role.node.id
  policy = data.aws_iam_policy_document.node_permissions.json
}

resource "aws_iam_instance_profile" "node" {
  name = "${var.name_prefix}-node-profile"
  role = aws_iam_role.node.name
}

resource "aws_key_pair" "node" {
  count      = var.ssh_public_key != "" ? 1 : 0
  key_name   = "${var.name_prefix}-key"
  public_key = var.ssh_public_key
}

resource "aws_security_group" "instance" {
  name        = "${var.name_prefix}-instance-sg"
  description = "Instance security group for ${var.name_prefix}"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name_prefix}-instance-sg" })
}

resource "aws_security_group_rule" "instance_from_lb" {
  for_each = { for p in var.app_ports : tostring(p.port) => p }

  type                     = "ingress"
  security_group_id        = aws_security_group.instance.id
  from_port                = tonumber(each.key)
  to_port                  = tonumber(each.key)
  protocol                 = "tcp"
  source_security_group_id = var.lb_security_group_id
  description              = "Load balancer to ${each.value.name}:${each.key}"
}

resource "aws_security_group_rule" "instance_ssh" {
  count = length(var.admin_cidrs) > 0 ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.instance.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.admin_cidrs
  description       = "Break-glass SSH access"
}

resource "aws_security_group_rule" "instance_egress" {
  type              = "egress"
  security_group_id = aws_security_group.instance.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

locals {
  ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.al2023_arm64.id

  user_data_template = var.os_family == "ubuntu" ? "userdata_ubuntu.tftpl" : "userdata.tftpl"

  instance_subnets = [
    for i in range(var.node_count) : var.private_subnet_ids[i % length(var.private_subnet_ids)]
  ]
}

resource "aws_instance" "node" {
  count = var.node_count

  ami                    = local.ami_id
  instance_type          = var.instance_type
  subnet_id              = local.instance_subnets[count.index]
  iam_instance_profile   = aws_iam_instance_profile.node.name
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name               = length(aws_key_pair.node) > 0 ? aws_key_pair.node[0].key_name : null

  user_data = templatefile("${path.module}/${local.user_data_template}", {
    node_name       = "${var.name_prefix}-${count.index}"
    aws_region      = var.aws_region
    user_data_extra = var.user_data_extra
  })

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_gb
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-${count.index}"
    NodeIndex = tostring(count.index)
    Stack     = var.name_prefix
  })

  lifecycle {
    ignore_changes = [ami]
  }
}

# prevent_destroy must be a literal — Terraform forbids referencing a
# variable there (it needs to know at parse time, before any value is
# evaluated). Split into two resources, gated by count on the same
# condition, and pick whichever one is actually created via a local.
resource "aws_ebs_volume" "data_mutable" {
  count = var.data_volume_gb > 0 && !var.data_volume_prevent_destroy ? var.node_count : 0

  availability_zone = aws_instance.node[count.index].availability_zone
  size              = var.data_volume_gb
  type              = "gp3"
  encrypted         = true

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-data-${count.index}"
    NodeIndex = tostring(count.index)
    Stack     = var.name_prefix
    Backup    = var.backup_policy_enabled ? var.backup_policy_name : "disabled"
  })

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_ebs_volume" "data_protected" {
  count = var.data_volume_gb > 0 && var.data_volume_prevent_destroy ? var.node_count : 0

  availability_zone = aws_instance.node[count.index].availability_zone
  size              = var.data_volume_gb
  type              = "gp3"
  encrypted         = true

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-data-${count.index}"
    NodeIndex = tostring(count.index)
    Stack     = var.name_prefix
    Backup    = var.backup_policy_enabled ? var.backup_policy_name : "disabled"
  })

  lifecycle {
    prevent_destroy = true
  }
}

locals {
  # Only one of the two resources above is ever created (count is mutually
  # exclusive), so concat just picks whichever one is non-empty.
  data_volumes = concat(aws_ebs_volume.data_mutable, aws_ebs_volume.data_protected)
}

resource "aws_volume_attachment" "data" {
  count = var.data_volume_gb > 0 ? var.node_count : 0

  device_name  = "/dev/sdf"
  volume_id    = local.data_volumes[count.index].id
  instance_id  = aws_instance.node[count.index].id
  force_detach = false

  # Stop the instance before detaching so replacing an instance (for example
  # with `-replace` during an image rollout) never detaches a mounted
  # filesystem from a running instance. The volume is kept and reattached.
  stop_instance_before_detaching = true
}

resource "aws_iam_role_policy_attachment" "extra" {
  for_each = toset(var.extra_policy_arns)

  role       = aws_iam_role.node.name
  policy_arn = each.value
}

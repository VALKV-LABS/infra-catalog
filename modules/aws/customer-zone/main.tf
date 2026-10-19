# Customer-dedicated compute zone: the network and identity a control plane
# launches per-customer VMs into.
#
# Extracted from prod-allcpservices-us-east-1, where these resources shared a
# Terraform state with the platform's own app tier. That meant changing a
# global-cp instance type ran an apply against the state holding every
# customer's network isolation boundary. Splitting it also makes the zone
# per-region rather than per-environment, which is what a second region needs.
#
# The invariant this module exists to keep: Terraform owns everything whose
# count is O(regions); the control plane owns everything whose count is
# O(customers). Nothing here scales with the customer table — the control plane
# calls RunInstances into these subnets at runtime.

locals {
  az_count = length(var.availability_zones)

  # One summarizable supernet, then per-AZ /24s inside it. A single supernet
  # rather than a list of unrelated subnets means the proxy-side return route
  # is one entry, not a per-AZ zip that breaks the moment the two sides
  # disagree about how many AZs they have.
  supernet     = cidrsubnet(var.vpc_cidr, var.supernet_newbits, var.supernet_index)
  subnet_cidrs = [for i in range(local.az_count) : cidrsubnet(local.supernet, 4, i)]

  peering_enabled = var.proxy_peering_connection_id != "" && var.proxy_vpc_cidr != ""

  tags = merge(var.tags, {
    Project     = "valkv"
    Component   = "customer-zone"
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# ── Subnets ───────────────────────────────────────────────────────────────────

resource "aws_subnet" "this" {
  count             = local.az_count
  vpc_id            = var.vpc_id
  cidr_block        = local.subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.tags, {
    Name = "${var.name_prefix}-customer-${count.index}"
  })
}

# ── Egress ────────────────────────────────────────────────────────────────────
# Own NAT gateways, not the platform tier's. Kept structurally separate so NAT
# Gateway CloudWatch metrics stay attributable to customer traffic rather than
# being mixed with the platform's own egress.

resource "aws_eip" "nat" {
  count  = local.az_count
  domain = "vpc"
  tags   = merge(local.tags, { Name = "${var.name_prefix}-customer-nat-eip-${count.index}" })
}

resource "aws_nat_gateway" "this" {
  count         = local.az_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = var.public_subnet_ids[count.index]
  tags          = merge(local.tags, { Name = "${var.name_prefix}-customer-nat-${count.index}" })
}

resource "aws_route_table" "this" {
  count  = local.az_count
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = merge(local.tags, { Name = "${var.name_prefix}-rt-customer-${count.index}" })
}

resource "aws_route_table_association" "this" {
  count          = local.az_count
  subnet_id      = aws_subnet.this[count.index].id
  route_table_id = aws_route_table.this[count.index].id
}

# ── Peering routes ────────────────────────────────────────────────────────────
# The proxy is what actually routes customer HTTP traffic to each instance's
# app port, so both directions need a route. This module writes them but does
# not create the peering itself — whichever tier owns that relationship does.

resource "aws_route" "to_proxy" {
  count                     = local.peering_enabled ? local.az_count : 0
  route_table_id            = aws_route_table.this[count.index].id
  destination_cidr_block    = var.proxy_vpc_cidr
  vpc_peering_connection_id = var.proxy_peering_connection_id
}

resource "aws_route" "proxy_to_here" {
  count                     = local.peering_enabled ? length(var.proxy_private_route_table_ids) : 0
  route_table_id            = var.proxy_private_route_table_ids[count.index]
  destination_cidr_block    = local.supernet
  vpc_peering_connection_id = var.proxy_peering_connection_id
}

# ── Per-product security groups ───────────────────────────────────────────────
# One per product, not one shared. Customer instances of different products
# have no reason to be mutually reachable, and a shared group makes that
# impossible to express.

resource "aws_security_group" "product" {
  for_each = var.products

  name        = "${var.name_prefix}-customer-${each.key}"
  description = "Customer ${each.key} VMs, launched by that product's control plane"
  vpc_id      = var.vpc_id

  # One rule per port. CIDR-based rather than a security-group reference,
  # because an SG-to-SG rule cannot cross a VPC peering connection.
  dynamic "ingress" {
    for_each = each.value.app_ports

    content {
      description = "Port ${ingress.value} from the proxy tier over the peering"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = var.proxy_vpc_cidr != "" ? [var.proxy_vpc_cidr] : []
    }
  }

  egress {
    description = "Unrestricted outbound (image pull, ACME, AWS APIs). The NACL below is what actually constrains this to internet-yes, this-VPC-no."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name    = "${var.name_prefix}-customer-${each.key}"
    Product = each.key
  })
}

# ── Per-product instance identity ─────────────────────────────────────────────
# Deliberately NO Secrets Manager access. An earlier shared wildcard grant let
# any customer instance read any other tenant's registry credentials. SSM Core
# only, for Session Manager access with no inbound SSH.

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "product" {
  for_each = var.products

  name               = "${var.name_prefix}-customer-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = merge(local.tags, { Product = each.key })
}

resource "aws_iam_role_policy_attachment" "product_ssm" {
  for_each = var.products

  role       = aws_iam_role.product[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Everything else the product needs. SSM Core alone makes a profile that can open
# a Session Manager shell and nothing else — which is why this exists: this module
# publishes the instance profile to SSM, the control planes launch with whatever it
# publishes, and a profile that cannot do the product's job fails at boot rather
# than at apply.
#
# Flattened to "<product>|<arn>" keys because for_each needs one entry per
# attachment and Terraform has no nested for_each.
locals {
  product_policy_attachments = merge([
    for product, cfg in var.products : {
      for arn in distinct(concat(cfg.policy_arns, lookup(var.extra_product_policy_arns, product, []))) :
      "${product}|${arn}" => { product = product, arn = arn }
    }
  ]...)
}

resource "aws_iam_role_policy_attachment" "product_extra" {
  for_each = local.product_policy_attachments

  role       = aws_iam_role.product[each.value.product].name
  policy_arn = each.value.arn
}

resource "aws_iam_instance_profile" "product" {
  for_each = var.products

  name = "${var.name_prefix}-customer-${each.key}"
  role = aws_iam_role.product[each.key].name
  tags = merge(local.tags, { Product = each.key })
}

# ── Network ACL ───────────────────────────────────────────────────────────────
# The actual "internet yes, this VPC no" enforcement. Security groups cannot
# express it — their rules are allow-only — while NACLs are stateless and
# rule-ordered, so a deny can precede a broad allow.
#
# Attached only to these subnets. A subnet-level NACL cannot tell a customer's
# instance from a platform node sharing the same subnet, which is exactly why
# this zone has subnets of its own.

resource "aws_network_acl" "this" {
  vpc_id     = var.vpc_id
  subnet_ids = aws_subnet.this[*].id
  tags       = merge(local.tags, { Name = "${var.name_prefix}-customer-nacl" })

  # Inbound stays open: the per-product security groups above already restrict
  # inbound by CIDR and port. This NACL's job is purely the egress side.
  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Instance metadata (169.254.169.254).
  #
  # This rule does NOT block IMDS, despite what an earlier comment here claimed.
  # Metadata traffic goes to a link-local address served by the host; it never
  # traverses the subnet, so it is not evaluated against this NACL — the same
  # reason a security group cannot block it either.
  #
  # The control that actually works is on the instance:
  # MetadataOptions { HttpTokens = "required", HttpPutResponseHopLimit = 1 }, set by
  # launchInstance (packages/compute-provisioning/src/providers/aws/instances.js)
  # and asserted by a test, because it is the ONLY thing standing between a
  # container on a customer VM and that instance's credentials. Do not remove it on
  # the assumption that this rule is a backstop.
  #
  # The rule is kept because it costs nothing and does deny real egress to
  # 169.254.0.0/16 traffic that is NOT metadata, but it is not defence in depth for
  # IMDS and must not be described as such.
  egress {
    rule_no    = 90
    protocol   = "-1"
    action     = "deny"
    cidr_block = "169.254.169.254/32"
    from_port  = 0
    to_port    = 0
  }

  # No lateral movement into the platform's own VPC.
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "deny"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 0
  }

  egress {
    rule_no    = 200
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

# ── SSM publication ───────────────────────────────────────────────────────────
# Control planes read these at runtime instead of having ids baked into their
# container environment at apply time. That is what makes adding a region an
# apply in the new region rather than an apply plus a control-plane redeploy.

resource "aws_ssm_parameter" "subnet_ids" {
  count = var.publish_to_ssm ? 1 : 0
  name  = "${var.ssm_prefix}/customer_subnet_ids"
  type  = "String"
  value = join(",", aws_subnet.this[*].id)
  tags  = local.tags
}

resource "aws_ssm_parameter" "supernet" {
  count = var.publish_to_ssm ? 1 : 0
  name  = "${var.ssm_prefix}/customer_supernet"
  type  = "String"
  value = local.supernet
  tags  = local.tags
}

resource "aws_ssm_parameter" "security_group_id" {
  for_each = var.publish_to_ssm ? var.products : {}

  name  = "${var.ssm_prefix}/products/${each.key}/security_group_id"
  type  = "String"
  value = aws_security_group.product[each.key].id
  tags  = merge(local.tags, { Product = each.key })
}

# The role BEHIND the profile, which is a different thing and is what a trust
# policy names. BaaS needs it: each project VM assumes a per-project storage role
# whose trust policy must name this role as the principal
# (global-cp/src/services/baas-project-role.js). The profile name is not
# substitutable — sts:AssumeRole principals are roles.
resource "aws_ssm_parameter" "iam_role_arn" {
  for_each = var.publish_to_ssm ? var.products : {}

  name  = "${var.ssm_prefix}/products/${each.key}/iam_role_arn"
  type  = "String"
  value = aws_iam_role.product[each.key].arn
  tags  = merge(local.tags, { Product = each.key })
}

resource "aws_ssm_parameter" "iam_instance_profile" {
  for_each = var.publish_to_ssm ? var.products : {}

  name  = "${var.ssm_prefix}/products/${each.key}/iam_instance_profile"
  type  = "String"
  value = aws_iam_instance_profile.product[each.key].name
  tags  = merge(local.tags, { Product = each.key })
}

resource "aws_ssm_parameter" "gold_ami_id" {
  count = var.publish_to_ssm && var.gold_ami_id != "" ? 1 : 0
  name  = "${var.ssm_prefix}/gold_ami_id"
  type  = "String"
  value = var.gold_ami_id
  tags  = local.tags
}

# ── Per-product launch template ───────────────────────────────────────────────
# Moves the launch-time shape of a customer instance out of control-plane code and
# into Terraform, where it is declarative, reviewable and versioned.
#
# The reason this matters is not tidiness. MetadataOptions is the only thing between
# a process in a container on a customer VM and that instance's role credentials —
# the NACL deny on 169.254.169.254 cannot filter IMDS, see the comment on that rule.
# As arguments in launchInstance those two lines can be dropped in a JS edit. Here
# they are infrastructure, versioned, with a diff.
#
# What is deliberately NOT here: the network.
#
# AWS forbids combining a template's subnet/security-group settings with a
# NetworkInterfaces override on RunInstances — "if you specify a network interface,
# you must specify any security groups and subnets as part of the network
# interface". The control planes launch with NetworkInterfaces because that is the
# only way to force AssociatePublicIpAddress=false, and they choose the subnet per
# launch to spread across AZs. So network stays a launch-time argument, and the
# security group stays where it already is: published to SSM, read from the registry,
# and passed inside the network interface.
#
# Instance type is also left out: /apps and /baas size per plan (offering_shapes),
# so a template value would be overridden on every call and would only mislead.

resource "aws_launch_template" "product" {
  for_each = var.products

  name        = "${var.name_prefix}-customer-${each.key}"
  description = "Launch shape for ${each.key} customer instances in this zone. Network and instance type are supplied per launch; see the module comment."

  # Omitted when the zone publishes no gold AMI, so RunInstances must still supply
  # one — the same fallback the registry already has for gold_ami_id.
  image_id = var.gold_ami_id != "" ? var.gold_ami_id : null

  iam_instance_profile {
    name = aws_iam_instance_profile.product[each.key].name
  }

  # The actual IMDS control. http_endpoint stays enabled because the instances need
  # their own identity document and credentials; what matters is requiring IMDSv2
  # and a hop limit of 1, which stops a container reaching IMDS over the Docker
  # bridge. Do not raise the hop limit.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }

  # Root volume defaults. Encrypted by default, because a customer VM's disk holds
  # that customer's data and an unencrypted root is not something to opt into later.
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = false
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.tags, { Product = each.key })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(local.tags, { Product = each.key })
  }

  tags = merge(local.tags, { Product = each.key })

  lifecycle {
    # A new version on every change rather than mutating the current one, so a bad
    # launch shape can be rolled back by pointing at the previous version instead of
    # reconstructing it.
    create_before_destroy = true
  }
}

resource "aws_ssm_parameter" "launch_template_id" {
  for_each = var.publish_to_ssm ? var.products : {}

  name  = "${var.ssm_prefix}/products/${each.key}/launch_template_id"
  type  = "String"
  value = aws_launch_template.product[each.key].id
  tags  = merge(local.tags, { Product = each.key })
}

# The version is published separately and explicitly. Publishing "$Latest" would mean
# a Terraform apply silently changed the shape of instances launched by a control
# plane that was never redeployed — which is the coupling this whole SSM tree exists
# to remove, pointed the wrong way.
resource "aws_ssm_parameter" "launch_template_version" {
  for_each = var.publish_to_ssm ? var.products : {}

  name  = "${var.ssm_prefix}/products/${each.key}/launch_template_version"
  type  = "String"
  value = tostring(aws_launch_template.product[each.key].latest_version)
  tags  = merge(local.tags, { Product = each.key })
}

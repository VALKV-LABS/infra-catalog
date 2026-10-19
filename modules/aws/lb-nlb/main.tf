resource "aws_security_group" "lb" {
  name        = "${var.name_prefix}-nlb-sg"
  description = "Ingress for ${var.name_prefix} network load balancer"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name_prefix}-nlb-sg" })
}

resource "aws_security_group_rule" "lb_inbound" {
  for_each = toset(var.ingress_cidrs)

  type              = "ingress"
  security_group_id = aws_security_group.lb.id
  from_port         = var.listener_port
  to_port           = var.listener_port
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  description       = "Internet to NLB listener"
}

resource "aws_security_group_rule" "lb_inbound_extra" {
  for_each = {
    for pair in setproduct(var.extra_listeners, var.ingress_cidrs) :
    "${pair[0].name}-${pair[1]}" => pair
  }

  type              = "ingress"
  security_group_id = aws_security_group.lb.id
  from_port         = each.value[0].listener_port
  to_port           = each.value[0].listener_port
  protocol          = "tcp"
  cidr_blocks       = [each.value[1]]
  description       = "Internet to NLB listener (${each.value[0].name})"
}

resource "aws_security_group_rule" "lb_egress" {
  type              = "egress"
  security_group_id = aws_security_group.lb.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb" "main" {
  name               = substr("${var.name_prefix}-nlb", 0, 32)
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.lb.id]
  subnets            = var.subnet_ids
  tags               = merge(var.tags, { Name = "${var.name_prefix}-nlb" })
}

resource "aws_lb_target_group" "service" {
  name        = substr("${var.name_prefix}-nlb-tg", 0, 32)
  port        = var.target_port
  protocol    = var.target_protocol
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled  = true
    protocol = var.health_check_protocol
    port     = var.health_check_port
    # Only meaningful for HTTP/HTTPS; AWS rejects it on a TCP check.
    path                = var.health_check_protocol == "TCP" ? null : (var.health_check_path != "" ? var.health_check_path : null)
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-nlb-tg" })
}

resource "aws_lb_listener" "service" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service.arn
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-nlb-listener" })
}

resource "aws_lb_target_group" "extra" {
  for_each = { for l in var.extra_listeners : l.name => l }

  name        = substr("${var.name_prefix}-nlb-${each.value.name}", 0, 32)
  port        = each.value.target_port
  protocol    = each.value.target_protocol
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = each.value.health_check_protocol
    port                = each.value.health_check_port
    path                = each.value.health_check_protocol == "TCP" ? null : (each.value.health_check_path != "" ? each.value.health_check_path : null)
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-nlb-${each.value.name}-tg" })
}

resource "aws_lb_listener" "extra" {
  for_each = { for l in var.extra_listeners : l.name => l }

  load_balancer_arn = aws_lb.main.arn
  port              = each.value.listener_port
  protocol          = each.value.listener_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.extra[each.key].arn
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-nlb-${each.value.name}-listener" })
}

resource "aws_security_group" "lb" {
  name        = "${var.name_prefix}-lb-sg"
  description = "Ingress for ${var.name_prefix} load balancer"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name_prefix}-lb-sg" })
}

resource "aws_security_group_rule" "lb_inbound" {
  for_each = { for p in var.app_ports : tostring(p.port) => p }

  type              = "ingress"
  security_group_id = aws_security_group.lb.id
  from_port         = tonumber(each.key)
  to_port           = tonumber(each.key)
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidrs
  description       = "Internet to ${each.value.name}"
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
  name               = substr("${var.name_prefix}-alb", 0, 32)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = var.subnet_ids
  idle_timeout       = 60
  tags               = merge(var.tags, { Name = "${var.name_prefix}-alb" })
}

resource "aws_lb_target_group" "services" {
  for_each = { for p in var.app_ports : tostring(p.port) => p }

  name        = substr("${var.name_prefix}-${each.value.name}-tg", 0, 32)
  port        = tonumber(each.key)
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = each.value.health_check_path
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200-299"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-${each.value.name}-tg" })
}

resource "aws_lb_listener" "services" {
  for_each = { for p in var.app_ports : tostring(p.port) => p }

  load_balancer_arn = aws_lb.main.arn
  port              = tonumber(each.key)
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.services[each.key].arn
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-${each.value.name}-listener" })
}

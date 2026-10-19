resource "oci_network_load_balancer_network_load_balancer" "main" {
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-nlb"
  subnet_id      = var.public_subnet_id
  is_private     = false
  freeform_tags  = var.tags
}

resource "oci_network_load_balancer_backend_set" "service" {
  name                     = "tcp-service"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.main.id
  policy                   = "FIVE_TUPLE"

  health_checker {
    protocol           = var.health_check_protocol
    port               = var.health_check_port
    interval_in_millis = 10000
    timeout_in_millis  = 5000
    retries            = 3
  }
}

resource "oci_network_load_balancer_backend" "nodes" {
  for_each = var.instances

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.main.id
  backend_set_name         = oci_network_load_balancer_backend_set.service.name
  ip_address               = each.value.private_ip
  port                     = var.target_port
  name                     = "${each.key}-${var.target_port}"
}

resource "oci_network_load_balancer_listener" "service" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.main.id
  default_backend_set_name = oci_network_load_balancer_backend_set.service.name
  name                     = "tcp-${var.listener_port}"
  port                     = var.listener_port
  protocol                 = var.listener_protocol
}

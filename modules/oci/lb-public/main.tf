resource "oci_load_balancer_load_balancer" "main" {
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-lb"
  shape          = "flexible"
  subnet_ids     = [var.public_subnet_id]
  freeform_tags  = var.tags
  is_private     = false

  shape_details {
    minimum_bandwidth_in_mbps = var.min_bandwidth_mbps
    maximum_bandwidth_in_mbps = var.max_bandwidth_mbps
  }
}

resource "oci_load_balancer_backend_set" "services" {
  for_each = { for p in var.app_ports : p.name => p }

  load_balancer_id = oci_load_balancer_load_balancer.main.id
  name             = each.value.name
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol          = "HTTP"
    port              = each.value.port
    url_path          = each.value.health_check_path
    return_code       = 200
    interval_ms       = 10000
    timeout_in_millis = 5000
    retries           = 3
  }
}

locals {
  backend_pairs = {
    for pair in flatten([
      for instance_key, instance in var.instances : [
        for app in var.app_ports : {
          key        = "${instance_key}-${app.name}"
          backendset = app.name
          ip_address = instance.private_ip
          port       = app.port
        }
      ]
    ]) : pair.key => pair
  }
}

resource "oci_load_balancer_backend" "services" {
  for_each = local.backend_pairs

  load_balancer_id = oci_load_balancer_load_balancer.main.id
  backendset_name  = each.value.backendset
  ip_address       = each.value.ip_address
  port             = each.value.port
  weight           = 1
  backup           = false
  drain            = false
  offline          = false
}

resource "oci_load_balancer_listener" "services" {
  for_each = { for p in var.app_ports : p.name => p }

  load_balancer_id         = oci_load_balancer_load_balancer.main.id
  name                     = each.value.name
  port                     = each.value.port
  protocol                 = "HTTP"
  default_backend_set_name = oci_load_balancer_backend_set.services[each.key].name
}

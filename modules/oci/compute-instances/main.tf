data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

locals {
  nodes = {
    for idx in range(var.instance_count) : format("node-%02d", idx + 1) => {
      index               = idx
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[idx % length(data.oci_identity_availability_domains.ads.availability_domains)].name
    }
  }
}

resource "oci_core_instance" "nodes" {
  for_each = local.nodes

  compartment_id      = var.compartment_id
  availability_domain = each.value.availability_domain
  display_name        = "${var.name_prefix}-${each.key}"
  shape               = var.instance_shape
  freeform_tags       = var.tags

  dynamic "shape_config" {
    for_each = var.instance_shape_config != null ? [var.instance_shape_config] : []
    content {
      ocpus         = shape_config.value.ocpus
      memory_in_gbs = shape_config.value.memory_in_gbs
    }
  }

  source_details {
    source_type = "image"
    source_id   = var.image_id
  }

  create_vnic_details {
    subnet_id        = var.private_subnet_id
    assign_public_ip = false
    display_name     = "${var.name_prefix}-${each.key}-vnic"
    hostname_label   = replace(each.key, "-", "")
  }

  metadata = {
    ssh_authorized_keys = trimspace(var.ssh_public_key)
    user_data = base64encode(templatefile("${path.module}/userdata.tftpl", {
      node_name = "${var.name_prefix}-${each.key}"
    }))
  }
}

data "oci_core_volume_backup_policies" "predefined" {
  count = var.data_volume_enabled && var.backup_policy_name != "" ? 1 : 0

  filter {
    name   = "display_name"
    values = [var.backup_policy_name]
  }
}

resource "oci_core_volume" "data" {
  for_each = var.data_volume_enabled ? local.nodes : {}

  compartment_id      = var.compartment_id
  availability_domain = each.value.availability_domain
  display_name        = "${var.name_prefix}-${each.key}-data"
  size_in_gbs         = var.data_volume_size_gb
  vpus_per_gb         = var.data_volume_vpus_per_gb
  freeform_tags = merge(var.tags, {
    Backup = var.backup_policy_name != "" ? var.backup_policy_name : "disabled"
  })

  lifecycle {
    prevent_destroy = var.data_volume_prevent_destroy
  }
}

resource "oci_core_volume_backup_policy_assignment" "data" {
  for_each = var.data_volume_enabled && var.backup_policy_name != "" ? local.nodes : {}

  asset_id  = oci_core_volume.data[each.key].id
  policy_id = data.oci_core_volume_backup_policies.predefined[0].volume_backup_policies[0].id
}

resource "oci_core_volume_attachment" "data" {
  for_each = var.data_volume_enabled ? local.nodes : {}

  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.nodes[each.key].id
  volume_id       = oci_core_volume.data[each.key].id
  display_name    = "${var.name_prefix}-${each.key}-data-attach"
  is_read_only    = false
}

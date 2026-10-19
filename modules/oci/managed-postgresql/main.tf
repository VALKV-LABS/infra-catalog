resource "oci_psql_db_system" "this" {
  compartment_id = var.compartment_id
  db_version     = var.db_version
  display_name   = "${var.name_prefix}-postgres"
  shape          = var.shape
  instance_count = var.instance_count
  instance_ocpu_count = var.instance_ocpu_count
  instance_memory_size_in_gbs = var.instance_memory_size_in_gbs
  description    = var.description
  freeform_tags  = var.tags

  credentials {
    username = var.admin_username

    password_details {
      password_type  = var.password_type
      password       = var.password_type == "PLAIN_TEXT" ? var.admin_password : null
      secret_id      = var.password_type == "VAULT_SECRET" ? var.admin_password_secret_id : null
      secret_version = var.password_type == "VAULT_SECRET" ? var.admin_password_secret_version : null
    }
  }

  network_details {
    subnet_id = var.subnet_id
  }

  storage_details {
    is_regionally_durable = var.storage_is_regionally_durable
    system_type           = var.storage_system_type
    iops                  = var.storage_system_type == "OCI_OPTIMIZED_STORAGE" ? var.storage_iops : null
  }
}

data "oci_psql_db_system_connection_detail" "this" {
  db_system_id = oci_psql_db_system.this.id
}

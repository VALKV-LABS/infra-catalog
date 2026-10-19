variable "region_label" {
  type        = string
  description = "Names the log group, the SNS topic and every alarm, e.g. \"prod-us-east-1\". One tier per label."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,62}$", var.region_label))
    error_message = "region_label must be lowercase alphanumeric with dashes — it becomes part of a log group name and an SNS topic name."
  }
}

variable "monitoring_enabled" {
  type        = bool
  default     = true
  description = <<-EOT
    False creates the log group but no SNS topic and no alarms.

    The log group is NOT optional: the proxy's compose file passes
    awslogs-create-group=false, so without the group the container fails to start.
    Turning monitoring off must not break the tier it monitors.
  EOT
}

variable "create_default_alarms" {
  type        = bool
  default     = true
  description = "False keeps the SNS topic and metric filters (so the metrics exist and can be graphed) but creates no alarms. Useful while establishing what normal looks like in a new region."
}

variable "subscriptions" {
  type = list(object({
    protocol = string
    endpoint = string
  }))
  default     = []
  description = <<-EOT
    SNS subscriptions, e.g. [{ protocol = "email", endpoint = "ops@valkv.app" }].

    Empty is allowed and is NOT an error: the alarms still fire and are visible in
    the console, they just notify nobody. Same shape as krocks-redis's
    monitoring_subscriptions so there is one pattern for this, not two.
  EOT
}

variable "log_retention_days" {
  type        = number
  default     = 30
  description = <<-EOT
    Retention for the proxy tier's log group.

    These are access and diagnostic logs, not an audit trail, and the metric filters
    extract what the alarms need at ingest time — so retention only has to cover how
    far back a human would read during an incident.
  EOT

  validation {
    # CloudWatch only accepts this set; 0 means never expire, which is how a log
    # group quietly becomes the largest line on the bill.
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be one of CloudWatch's accepted values, and not 0 (never expire)."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

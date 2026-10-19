variable "name_prefix" {
  type        = string
  description = "Prefix for every resource name, e.g. valkv-prod-us-west-1."
}

variable "environment" {
  type        = string
  description = "Environment name, used in tags."
}

# ── Foundation inputs ─────────────────────────────────────────────────────────
# This module deliberately does NOT create a VPC. It carves a customer zone out
# of one that already exists, so the zone can live in its own Terraform state
# without that state also owning the platform's network.

variable "vpc_id" {
  type        = string
  description = "VPC to carve the customer zone out of."
}

variable "vpc_cidr" {
  type        = string
  description = "That VPC's CIDR. Used both to size the customer supernet and, in the NACL, as the range customer instances are denied egress to."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnets to place the customer NAT gateways in, one per AZ. Must be at least as long as availability_zones."
}

variable "availability_zones" {
  type        = list(string)
  description = "AZs to spread customer subnets across. Its length determines how many subnets, NATs and route tables are created."
}

variable "supernet_newbits" {
  type        = number
  default     = 4
  description = "Bits to add to vpc_cidr when carving the customer supernet. Default 4 turns a /16 into a /20."
}

variable "supernet_index" {
  type        = number
  default     = 2
  description = "Which block of that size to take. Default 2 clears the /24s the network-vpc module uses at indices 0-2 (public) and 10-12 (private) within the same /16."
}

# ── Products ──────────────────────────────────────────────────────────────────

variable "extra_product_policy_arns" {
  type        = map(list(string))
  default     = {}
  description = <<-EOT
    Additional policy ARNs to attach, keyed by product, merged with that product's
    own `policy_arns`.

    Separate from `products` so an operator can wire in ARNs that are another root
    module's outputs without restating the whole products map. BaaS is the case
    this exists for: its storage and artifacts policies are created by
    baas/terraform, so their ARNs are only known after that applies.

    A product named here that is not in `products` is rejected rather than
    ignored — a typo would otherwise silently leave the profile unpermissioned,
    which is the exact failure this variable exists to prevent.
  EOT

  validation {
    condition     = length(setsubtract(keys(var.extra_product_policy_arns), keys(var.products))) == 0
    error_message = "extra_product_policy_arns names a product that is not in `products`; nothing would attach it."
  }
}

variable "products" {
  type = map(object({
    app_ports   = list(number)
    policy_arns = optional(list(string), [])
  }))
  description = <<-EOT
    One entry per product that lands customer instances in this zone, e.g.
    { apps = { app_ports = [8080] }, cachedb = { app_ports = [6379] } }.

    A list, not a single port: a BaaS project VM serves REST, auth, realtime and
    storage on separate ports, so one-port-per-product cannot express it.

    Each product gets its OWN security group and IAM instance profile. They
    share the subnets, NAT gateways and NACL — those are network-level and
    carry no identity — but not an identity. In the environment this module
    was extracted from, /apps and cachedb dedicated instances shared one
    security group and one instance profile because both control planes read
    the same DEDICATED_* variables, which means a compromise of one product's
    VM carried the other product's permissions.

    `policy_arns` is what makes the published profile USABLE. A profile with no
    permissions is worse than no profile: the control plane reads it from SSM and
    launches with it, and the instance then fails at boot doing whatever it needed
    permissions for. This module publishes the profile, so it has to own what the
    profile can do.

    Use it for statically-known ARNs (AWS managed policies). ARNs that are outputs
    of another root module — BaaS's storage and artifacts policies live in
    baas/terraform — go in `extra_product_policy_arns` instead, because a default
    here cannot reference them.
  EOT

  validation {
    condition     = length(var.products) > 0
    error_message = "At least one product must be defined, otherwise this zone has no consumers."
  }

  validation {
    condition     = alltrue([for p in var.products : length(p.app_ports) > 0])
    error_message = "Every product needs at least one app_port. A product with none would get a security group that accepts nothing, and its instances would be unreachable from the proxy tier — a failure that surfaces only once a customer tries to use one."
  }
}

# ── Peering to the proxy tier ─────────────────────────────────────────────────
# Optional: a zone can be applied before the proxy tier exists, then re-applied
# once it does. All three must be set together.

variable "proxy_vpc_cidr" {
  type        = string
  default     = ""
  description = "Proxy tier's VPC CIDR. Customer instances accept their app port from this range only."
}

variable "proxy_peering_connection_id" {
  type        = string
  default     = ""
  description = "Existing peering connection to the proxy tier. This module does not create the peering — the tier that owns the relationship does — it only writes the routes its own subnets need."
}

variable "proxy_private_route_table_ids" {
  type        = list(string)
  default     = []
  description = "Proxy-side route tables that need a return route to this zone's supernet."
}

# ── SSM publication ───────────────────────────────────────────────────────────

variable "publish_to_ssm" {
  type        = bool
  default     = true
  description = <<-EOT
    Publish this zone's ids to SSM Parameter Store under ssm_prefix.

    This is what decouples adding a region from redeploying the control planes:
    they read the region-keyed prefix at runtime instead of having subnet and
    profile ids baked into their container environment at apply time.
  EOT
}

variable "ssm_prefix" {
  type        = string
  default     = ""
  description = "Parameter Store prefix, e.g. /valkv/prod/regions/us-west-1. Required when publish_to_ssm is true."
}

variable "gold_ami_id" {
  type        = string
  default     = ""
  description = "Customer VM gold image for this region. AMI ids are region-scoped, which is a large part of why this is published per region. Published only when non-empty."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to every resource."
}

# customer-zone

The network and identity a control plane launches **per-customer** VMs into:
subnets, dedicated NAT gateways, per-product security groups and IAM instance
profiles, and a NACL enforcing "internet yes, this VPC no".

## The invariant

> Terraform owns everything whose count is O(regions).
> The control plane owns everything whose count is O(customers).

Nothing in this module scales with the customer table. It builds a landing
zone; global-cp and cachedb-cp call `RunInstances` into it at runtime, reading
the ids from SSM. No Terraform state should ever grow as customers sign up.

## Why it is its own module

It was extracted from `prod-allcpservices-us-east-1`, where these resources
shared a state file with the platform's own app tier. Changing a global-cp
instance type therefore ran an apply against the state holding every
customer's network isolation boundary. Separating them bounds that blast
radius, and makes the zone per-region rather than per-environment — which is
what a second region needs.

## Per-product identity

`products` creates one security group and one IAM instance profile **per
product**. They share the subnets, NAT gateways and NACL, because those are
network-level and carry no identity, but they do not share an identity.

This differs from us-east-1 today, where `/apps` and cachedb dedicated
instances share one security group and one instance profile — both control
planes read the same `DEDICATED_*` variables. A compromise of one product's VM
carries the other product's permissions. Splitting is free in a new zone and a
deliberate rollout in an existing one.

The profiles carry **SSM Core only**. No Secrets Manager: an earlier shared
wildcard grant let any customer instance read any other tenant's registry
credentials.

## Inputs it does not take

- **A VPC.** It carves out of one that already exists, so the zone can live in
  its own state without that state also owning the platform's network.
- **A peering connection.** It writes the routes its own subnets need, but the
  tier that owns the peering relationship creates it. Pass the id in.

## SSM publication

With `publish_to_ssm`, ids are written under `ssm_prefix`:

```
<prefix>/customer_subnet_ids                       comma-separated
<prefix>/customer_supernet
<prefix>/gold_ami_id                               when set
<prefix>/products/<product>/security_group_id
<prefix>/products/<product>/iam_instance_profile
```

This is what decouples adding a region from redeploying the control planes.
They read the region-keyed prefix at runtime instead of having ids baked into
container environment at apply time. **That is the test of whether the split is
correct**: adding a region should be an apply in the new region, not an apply
plus a global-cp restart.

Today `DEDICATED_SUBNET_ID` is a bare id and single-region, while
`BAAS_SUBNET_ID` is already region-keyed (`us-east-1:subnet-...`). Moving the
former onto this prefix is the consumer-side half of the change and is tracked
in the plan.

## Usage

```hcl
module "customer_zone" {
  source = "../../../infra-catalog/modules/aws/customer-zone"

  name_prefix        = "valkv-prod-us-west-1"
  environment        = "prod"
  vpc_id             = module.foundation.vpc_id
  vpc_cidr           = module.foundation.vpc_cidr_block
  public_subnet_ids  = module.foundation.public_subnet_ids
  availability_zones = module.foundation.availability_zones

  products = {
    apps    = { app_ports = [8080] }
    cachedb = { app_ports = [6379] }
    baas    = { app_ports = [3000, 9999, 4000, 5000] }
  }

  publish_to_ssm = true
  ssm_prefix     = "/valkv/prod/regions/us-west-1"
}
```

## CIDR layout

`supernet_newbits` / `supernet_index` carve one summarizable supernet out of
the VPC, then per-AZ `/24`s inside it. Defaults (`4`, `2`) turn a `/16` into a
`/20` at an index clear of the `network-vpc` module's own `/24`s (0-2 public,
10-12 private).

One supernet rather than a list of unrelated subnets means a peered tier needs
**one** return route, not a per-AZ zip that breaks the moment the two sides
disagree about how many AZs they have.

## Adopting an existing zone

Applying this against an empty state does **not** adopt existing resources — it
builds a parallel zone, with new NAT gateways and new egress IPs, while the old
one keeps running. Adoption is a `terraform state mv` migration; see
`valkv-platform-infra/docs/multi-region-plan.md` section 5. `plan` must come
back empty on both states before it is done.

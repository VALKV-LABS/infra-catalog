# infra-catalog

Reusable Terraform catalog for bootstrapping compute infrastructure on AWS and OCI.

This directory is the shared catalog source. A user can run these stacks directly with Terraform, wrap them with Terragrunt, or call them from Cloudlaunch or another deployment pipeline. The stacks do not assume Cloudlaunch-specific behavior.

## Goals

- Reusable starter stacks instead of one-off environment code
- Provider-specific building blocks under a shared catalog shape
- Optional attached storage and backup policies built into the catalog items
- Stable input and output contracts that work for humans and pipelines
- Safe-by-default infrastructure behavior with configurable cost and performance

## Directory Layout

```text
infra-catalog/
  modules/
    aws/
      compute-instances/
      ebs-backup-policy/
      lb-alb/
      network-vpc/
    oci/
      compute-instances/
      lb-public/
      network-vcn/
  stacks/
    aws/
      instances-with-lb/
      instances-with-nlb/
      instances-with-lb-postgresql/
    oci/
      instances-with-lb/
      instances-with-nlb/
      instances-with-lb-postgresql/
  catalog/
    index.yaml
```

## Catalog Items

### `aws/instances-with-lb`

Provisions:

- VPC, subnets, IGW, and NAT
- Public application load balancer
- Private EC2 instances
- IAM profile with SSM and CloudWatch access
- ECR read-only pull access through the instance profile by default
- Optional attached EBS data volume per node
- Optional EBS snapshot lifecycle policy

### `aws/instances-with-nlb`

Provisions:

- VPC, subnets, IGW, and NAT
- Public network load balancer
- Private EC2 instances
- ECR read-only pull access through the instance profile by default
- TCP listener on `443` by default, forwarded to a configurable instance port
- Optional attached EBS data volume per node
- Optional EBS snapshot lifecycle policy

### `oci/instances-with-lb`

Provisions:

- VCN, subnets, IGW, NAT, and service gateway
- Public OCI load balancer
- Private OCI compute instances
- Optional attached block volume per node
- Optional OCI predefined backup policy assignment

### `oci/instances-with-nlb`

Provisions:

- VCN, subnets, IGW, NAT, and service gateway
- Public OCI network load balancer
- Private OCI compute instances
- TCP listener on `443` by default, forwarded to a configurable instance port
- Optional attached block volume per node
- Optional OCI predefined backup policy assignment

### `aws/instances-with-lb-postgresql`

Provisions:

- Everything from the AWS app stack
- Managed RDS PostgreSQL on private subnets
- Security group access from app instances to PostgreSQL
- Managed master password secret
- Configurable RDS instance class, storage, retention, and deletion behavior

### `oci/instances-with-lb-postgresql`

Provisions:

- Everything from the OCI app stack
- Managed OCI PostgreSQL on private subnets
- Configurable PostgreSQL shape, OCPU count, and memory
- Configurable password source using plaintext or OCI Vault secret references
- TLS connection metadata outputs including CA certificate

## Standard Inputs

The provider stacks use a similar contract where possible:

- `name`
- `region`
- `instance_count`
- `app_ports`
- `ssh_public_key`
- `allowed_cidrs_admin`
- `data_volume_enabled`
- `data_volume_size_gb`
- `backup_policy_enabled` or `backup_policy_name`
- `ecr_read_only_enabled` for AWS instance stacks
- `tags`

That makes the stacks easy to consume from Terraform, Terragrunt, or Cloudlaunch pipelines that inject environment-specific variables.

## Networks Without NAT

`modules/aws/network-vpc` creates NAT gateways by default. For development
cells where the NAT gateway is the largest fixed cost, set
`nat_gateway_enabled = false`: no NAT gateways or Elastic IPs are created, and
the private subnets get no default route. Instances that need egress then run
in `public_subnet_ids` with `compute-instances`' `associate_public_ip_address =
true`. Each instance gets a public IPv4 address (billed hourly) and outbound
traffic goes through the internet gateway; inbound traffic is still limited
to the instance security group's rules, so do not open them to `0.0.0.0/0`
unless the port is meant to be public.

## Instance Tags in Metadata

`modules/aws/compute-instances` keeps instance tags out of the instance
metadata service by default. Set `instance_metadata_tags_enabled = true` to
let software on the instance read them at
`http://169.254.169.254/latest/meta-data/tags/instance/<key>`, for example a
boot script that takes a node class from a tag instead of user data. Tag keys
containing `/` are not exposed, so use keys like `valkvork-node-class`. The
metadata hop limit stays 1, so containers on the instance cannot read them.
Changing the setting updates running instances in place.

## Best-Practice Expectations

The catalog is intended to follow standard infrastructure best practices:

- resources should accept and pass through tags where the provider supports them
- databases and internal services should default to private networking
- encryption at rest should be enabled where supported
- backups should be enabled or explicitly configurable
- stateful services should make deletion protection and final snapshot behavior explicit
- outputs should include the operational details needed by downstream automation
- AWS instance stacks should support ECR pulls through instance profile credentials by default, with an opt-out variable

These rules are captured in [AGENTS.md](C:/Users/prabh/Desktop/workspace/valkv/infra-catalog/AGENTS.md) and should be followed whenever new modules or stacks are added.

## Storage Policy

Attached storage is part of the same catalog item rather than a separate product.

- AWS: optional EBS data volume plus optional DLM snapshot policy
- OCI: optional block volume plus optional predefined backup policy assignment

This keeps the catalog small while still covering both stateless and stateful app nodes.

Consumer repos can point their Terraform root modules at these stacks by relative path or by packaging this directory as a module source.

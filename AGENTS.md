# Infra Catalog Agent Guide

This file defines the working rules for `infra-catalog`.

## Purpose

`infra-catalog` is the shared Terraform catalog for reusable infrastructure stacks. It is not a product repo and it is not a deployment-specific wrapper. Consumer repos such as `valkv-platform-infra` should reference stacks from here.

The goal is to keep this catalog:

- reusable outside ValKV
- safe by default
- provider-native where it matters
- easy to consume from Terraform, Terragrunt, and deployment pipelines

## Ownership Boundaries

- `modules/` contains provider-specific low-level building blocks.
- `stacks/` contains reusable opinionated catalog items composed from modules.
- `catalog/index.yaml` is the discoverability layer and must be updated when catalog items are added, renamed, or removed.
- Consumer-specific environment wrappers do not belong here.
- Product-specific deployment logic, app bootstrap scripts, and tenant-specific workflows do not belong here unless they are genuinely reusable infrastructure behavior.

## Catalog Rules

1. Every new catalog item must have:
   - a stack directory under `stacks/<provider>/...`
   - documented inputs and outputs
   - an entry in `catalog/index.yaml`
   - a README update when the catalog surface changes
2. Do not publish half-finished stacks.
   - If the stack does not exist, is missing key outputs, or is not coherent enough to consume, do not add it to `catalog/index.yaml`.
3. Prefer provider-native naming for configurable SKUs:
   - AWS examples: `t4g.micro`, `db.t4g.micro`, `db.r6g.large`
   - OCI examples: shape plus OCPU and memory inputs
4. Keep the base stack small.
   - Optional attached disk belongs in the base compute stack.
   - Managed databases such as PostgreSQL should usually be separate catalog items.
5. Catalog stacks must remain usable by:
   - direct Terraform
   - Terragrunt
   - Cloudlaunch or similar pipelines
6. Do not hardcode consumer-repo assumptions into modules or stacks.

## Infrastructure Best Practices

All catalog items should follow these defaults unless there is a strong documented reason not to.

### Tagging

- Every reusable module should accept a `tags` input when the provider supports it.
- Every stack should accept `tags` and pass them through to underlying modules.
- Tags should be applied consistently to all supported resources.
- Avoid hardcoding organization-specific tags beyond what the stack itself must identify.

### Networking

- Private-by-default for databases and internal services.
- Public ingress should exist only where explicitly needed.
- Use least-privilege security groups, NSGs, or firewall rules.
- Avoid broad `0.0.0.0/0` access except where the catalog item is intentionally public and the behavior is documented.

### Encryption and Secrets

- Enable encryption at rest where the provider supports it.
- Prefer provider-native secret handling for managed credentials.
- Do not expose plaintext secrets in outputs.
- Treat Terraform state as sensitive whenever credentials may flow through it.
- AWS instance stacks should support ECR image pulls via instance profile credentials by default, and expose an opt-out variable for stricter environments.

### Stateful Resources

- Backups should be enabled or explicitly configurable.
- Deletion protection, final snapshot behavior, and retention must be explicit for stateful resources.
- Stateful resources should expose clear operational outputs such as endpoint, port, secret reference, and resource IDs.

### Observability and Operations

- Prefer provider-native management agents and monitoring hooks where reasonable.
- Expose outputs operators actually need, not just internal IDs.
- Prefer predictable naming and outputs over clever abstraction.

### Cost and Performance

- Use reasonable low-cost defaults for dev-friendly stacks.
- Allow instance class, shape, storage size, and backup retention to be configured.
- Do not hide expensive HA or backup settings behind hardcoded values.

## Stack Design Guidance

- Favor composition over giant cross-cloud modules.
- Separate provider-specific implementation under `modules/<provider>/`.
- Keep stack interfaces similar across providers when practical, but do not fake identical behavior where providers differ materially.
- Prefer a small number of strong catalog items over many overlapping variants.

Examples:

- Good: `aws-instances-with-lb`
- Good: `aws-instances-with-lb-postgresql`
- Good: `oci-instances-with-lb`
- Avoid: one giant `instances-with-lb` stack with `cloud = "aws|oci|hetzner"`

## Inputs and Outputs

- Inputs should be stable, predictable, and named for user intent.
- Outputs should be high-signal and useful to downstream automation.
- Stateful stacks should expose connection details and secret references.
- Prefer explicit variables for safety-sensitive behavior such as deletion protection and backup retention.

## Change Expectations

- When adding a stateful service, expose clear connection outputs.
- When adding secrets-managed resources, prefer provider-native secret handling where practical.
- When changing stack contracts, update the README and catalog metadata in the same change.
- If a new stack is only partially implemented, do not publish it in `catalog/index.yaml` until the stack exists and has coherent outputs.
- If a module cannot support tagging because of provider limitations, document that explicitly in code comments or README notes.

## Naming Guidance

- Prefer concise IDs such as `aws-instances-with-lb-postgresql`.
- Avoid repetitive names like `with-with`.
- Avoid abstract names that hide important provider differences.
- Keep stack directory names aligned with catalog item IDs where possible.

## Validation

- Run `terraform fmt` and `terraform validate` when the toolchain is available. OpenTofu (`tofu fmt`, `tofu validate`) is installed locally and validates the same code.
- If validation cannot be run, say so explicitly and note why.
- When adding a new stack, sanity-check that every referenced module path exists and that catalog metadata matches the stack name and outputs.

## Git Authorship

- Every commit must be authored and committed as `joti-valkv <joti@valkv.com>`. Set it in the repository before committing:
  `git config user.name joti-valkv && git config user.email joti@valkv.com`
- Do not add `Co-Authored-By` or any other attribution trailers to commit messages, and do not add "Generated with" footers to pull request descriptions.
- Create pull requests with `gh` while authenticated as `joti-valkv`.

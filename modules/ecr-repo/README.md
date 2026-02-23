# ecr-repo

Terraform module that creates one or more **private Amazon ECR repositories** with security and hygiene defaults: image scanning on push, tag immutability, and lifecycle policies to limit storage bloat.

## Requirements

- Terraform `>= 1.5.0`
- AWS provider `>= 5.0`

## What this module creates

For each entry in `repositories`:

- An **ECR repository** with:
  - **Image scanning on push** (default: enabled) — surfaces CVEs at push time.
  - **Tag immutability** (default: `IMMUTABLE`) — prevents overwriting image tags and avoids drift between environments.
  - **AES256** encryption at rest.
  - Tags merged from `var.tags` plus a `Module = "ecr-repo"` marker.

- A **lifecycle policy** with two rules:
  1. **Untagged images**: expire images that have been untagged for longer than `untagged_expire_days` (default 7).
  2. **Tagged images**: keep only the newest `keep_tagged_max_count` (default 20) images whose tags match the repository’s `tags_prefixes` (e.g. `v`, `sha-`); older matching images are expired.

## Why these defaults

- **Scan on push** — Finds vulnerabilities early; you can block deployments or fix before promotion.
- **Immutable tags** — Ensures a tag always points to the same image; deployments that pin a tag don’t silently get a new digest.
- **Lifecycle cleanup** — Reduces storage cost and clutter: untagged layers and old tagged versions beyond the retained window are expired.

Downstream deployments should **pin immutable tags or digests** (e.g. `scraper:v1.2.3` or `scraper@sha256:...`) so that what runs in production does not drift from what was tested.

## Usage

```hcl
module "ecr" {
  source = "../../modules/ecr-repo"  # or your module source

  repositories = {
    scraper = { tags_prefixes = ["v", "sha-"] }
  }
  # scan_on_push = true
  # immutability = "IMMUTABLE"
  # untagged_expire_days = 7
  # keep_tagged_max_count = 20

  tags = { Project = "web-scraper" }
}

output "ecr_urls" {
  value = module.ecr.repository_urls
}
```

## Tuning lifecycle behavior

- **untagged_expire_days** — How long untagged images are kept before expiry (default `7`). Increase if you need a longer window for debugging.
- **keep_tagged_max_count** — How many of the newest tagged images (per prefix) to retain (default `20`). Increase for longer history; decrease to save storage.
- **tags_prefixes** (per repository) — Only tags starting with these prefixes are subject to the “keep newest N” rule. Use `["v"]` for semver tags, `["sha-"]` for commit-based tags, or both. Images with other tag patterns are not managed by rule 2 (only by untagged rule if they become untagged).

## Private pulls without NAT (informational)

If you want fully private image pulls without sending traffic through a NAT Gateway, you can add **VPC endpoints** in your network (VPC) module:

- **Interface endpoints** for ECR: `com.amazonaws.<region>.ecr.api` and `com.amazonaws.<region>.ecr.dkr`.
- **Gateway endpoint** for S3 (ECR uses S3 for layer storage).

This module does not create VPC endpoints; it only creates the ECR repositories and their lifecycle policies.

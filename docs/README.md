## infra-modules

This repository contains reusable Terraform modules for the **web-scraper** project.

### Available modules

- **`s3-secure-bucket`**: Creates a private, secure-by-default S3 bucket with:
  - Ownership controls (`BucketOwnerEnforced`)
  - Public access block
  - Default encryption (SSE-S3 or SSE-KMS)
  - Versioning
  - Optional TLS-only bucket policy
  - Optional server access logging

See `modules/s3-secure-bucket/README.md` for full input/output reference and usage.

- **`vpc-minimal`**: Minimal production-sane VPC with outbound-only internet for private subnets:
  - VPC with DNS support/hostnames, IGW, two public subnets (NAT + IGW), two private subnets (route to NAT per AZ)
  - Optional S3 gateway endpoint (default on), optional interface endpoints (ECR, Logs, Secrets Manager)
  - Shared endpoint security group when any interface endpoints are enabled

See `modules/vpc-minimal/README.md` for details.

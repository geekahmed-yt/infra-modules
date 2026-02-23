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

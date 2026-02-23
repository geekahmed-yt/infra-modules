## infra-modules

Terraform modules for the **web-scraper** project.

### Getting started

1. Ensure you have Terraform `>= 1.5.0` and AWS provider `>= 5.0`.
2. Browse `modules/` for reusable modules.
3. Use the `examples/` directory to try modules in isolation.

### Modules

- **`s3-secure-bucket`** – creates a secure, private S3 bucket with:
  - Ownership controls
  - Public access block
  - Encryption (SSE-S3 / SSE-KMS)
  - Versioning
  - Optional TLS-only policy and access logging

See `docs/README.md` and `modules/s3-secure-bucket/README.md` for details.


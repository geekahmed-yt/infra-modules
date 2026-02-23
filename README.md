## infra-modules

Terraform modules for the **web-scraper** project.

### Getting started

1. Ensure you have Terraform `>= 1.5.0` and AWS provider `>= 5.0`.
2. Browse `modules/` for reusable modules.
3. Use the `examples/` directory to try modules in isolation.

### Modules

- **`s3-secure-bucket`** – creates a secure, private S3 bucket (ownership controls, encryption, versioning, optional TLS-only and access logging).
- **`vpc-minimal`** – minimal VPC with outbound-only internet for private subnets (public subnets for NAT + IGW, private subnets route to NAT per AZ, optional S3/ECR/Logs/Secrets endpoints).

See `docs/README.md` and each module’s `README.md` for details.


# s3-secure-bucket-basic

Minimal example that creates a secure S3 bucket using the `s3-secure-bucket` module.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

Override the region if needed:

```bash
terraform apply -var="aws_region=eu-west-1"
```

## Outputs

After applying, the example exposes: `bucket_name`, `bucket_arn`, `bucket_id`, `bucket_region`.

## Files

- `main.tf` — Terraform and provider config, module call, random suffix for bucket name
- `variables.tf` — `aws_region` (default: `us-east-1`)
- `outputs.tf` — Bucket attributes from the module

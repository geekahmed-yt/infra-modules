## infra-modules examples

### `s3-secure-bucket-basic`

Minimal example that creates a secure S3 bucket using the `s3-secure-bucket` module. Uses multi-line Terraform blocks, a dedicated `variables.tf` and `outputs.tf`, and exposes bucket name, ARN, ID, and region.

To run:

```bash
cd examples/s3-secure-bucket-basic
terraform init
terraform apply
```

See the [example README](s3-secure-bucket-basic/README.md) for details.


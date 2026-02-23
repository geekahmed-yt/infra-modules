# s3-secure-bucket

Terraform module that creates a **private, secure-by-default S3 bucket** with ownership controls, encryption, versioning, and optional TLS enforcement and access logging.

## Requirements

| Name      | Version   |
| --------- | --------- |
| terraform | `>= 1.5.0` |
| aws       | `>= 5.0`  |

## Features

- **Object ownership** — ACLs disabled via `BucketOwnerEnforced` (recommended for new buckets).
- **Public access** — All four S3 Block Public Access settings enabled by default.
- **Encryption** — Server-side encryption: SSE-S3 by default, or SSE-KMS with an optional KMS key and S3 Bucket Keys.
- **Versioning** — Enabled by default; can be suspended.
- **Lifecycle** — Optional rule to abort incomplete multipart uploads after a set number of days (cost control).
- **TLS only** — Optional bucket policy that denies requests when `aws:SecureTransport` is false.
- **Access logging** — Optional server access logging to another S3 bucket (set `access_log_bucket_id`).

## Usage

### Basic (SSE-S3)

```hcl
module "bucket" {
  source = "../../modules/s3-secure-bucket"  # or your module source

  bucket_name = "my-app-bucket"
  tags = {
    Project = "my-app"
  }
}
```

### With access logging

```hcl
module "bucket" {
  source = "../../modules/s3-secure-bucket"

  bucket_name           = "my-app-bucket"
  access_log_bucket_id  = "my-central-logs-bucket"
  access_log_prefix     = "s3/my-app/"
  tags                  = { Project = "my-app" }
}
```

### With SSE-KMS

When using `sse_mode = "SSE-KMS"`, you must provide a KMS key ARN.

```hcl
module "bucket" {
  source = "../../modules/s3-secure-bucket"

  bucket_name         = "my-app-bucket"
  sse_mode            = "SSE-KMS"
  kms_key_arn         = aws_kms_key.s3.arn
  bucket_key_enabled  = true
  tags                = { Project = "my-app" }
}
```

## Inputs

| Name                         | Type        | Default                 | Description |
| ---------------------------- | ----------- | ----------------------- | ----------- |
| `bucket_name`                | `string`    | (required)              | Name of the S3 bucket. |
| `force_destroy`              | `bool`      | `false`                 | Allow Terraform to destroy the bucket even if it is not empty. |
| `tags`                       | `map(string)` | `{}`                  | Tags to apply to the bucket. |
| `object_ownership_mode`       | `string`    | `"BucketOwnerEnforced"` | S3 object ownership mode. |
| `block_public_access`        | `bool`      | `true`                  | Block all public access (ACLs, policies, etc.). |
| `sse_mode`                   | `string`    | `"SSE-S3"`              | Server-side encryption: `SSE-S3` or `SSE-KMS`. |
| `kms_key_arn`                | `string`    | `null`                  | KMS key ARN when `sse_mode` is `SSE-KMS`. Required when using SSE-KMS. |
| `bucket_key_enabled`         | `bool`      | `true`                  | Use S3 Bucket Keys for KMS when `sse_mode` is `SSE-KMS`. |
| `enable_versioning`          | `bool`      | `true`                  | Enable versioning on the bucket. |
| `enable_abort_incomplete_mpu`| `bool`      | `true`                  | Enable lifecycle rule to abort incomplete multipart uploads. |
| `abort_incomplete_mpu_after_days` | `number` | `7`                 | Days after which incomplete multipart uploads are aborted. |
| `enforce_tls_only`           | `bool`      | `true`                  | Attach a bucket policy that denies non-HTTPS requests. |
| `access_log_bucket_id`       | `string`    | `null`                  | Bucket ID for server access logs; if set, access logging is enabled. |
| `access_log_prefix`          | `string`    | `"logs/"`               | Object key prefix for access logs in the target bucket. |

## Outputs

| Name           | Description |
| -------------- | ----------- |
| `bucket_id`    | The ID of the S3 bucket. |
| `bucket_arn`   | The ARN of the S3 bucket. |
| `bucket_name` | The name of the S3 bucket. |
| `bucket_region`| The AWS region of the S3 bucket. |

## Examples

See the [s3-secure-bucket-basic](../../examples/s3-secure-bucket-basic) example in the repo for a minimal working configuration.

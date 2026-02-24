# lambda-fn

Terraform module that creates an **AWS Lambda function** for a transformer (or similar workload) that reads from a raw S3 prefix and writes to a processed prefix. The deployment package can be supplied from **S3** or a **local zip**. The execution role is supplied externally (e.g. from the **iam-runtime** module).

## Requirements

- Terraform `>= 1.5.0`
- AWS provider `>= 5.0`

## Packaging modes

- **`package_source = "s3"`** — Lambda code is taken from an S3 object. Set `s3_bucket` and `s3_key`. Use this when you publish artifacts to S3 (e.g. from CI).
- **`package_source = "local"`** — Lambda code is a local zip file. Set `filename` to the path to the zip. Terraform uploads it on apply. Use this for local or module-relative paths (e.g. `artifacts/transformer.zip`).

## Execution role (supplied externally)

The Lambda **execution role** is passed in via `role_arn`. This module does **not** create or attach IAM policies. The role **must** include:

1. **CloudWatch Logs** — So Lambda can create and write log streams. Required actions: `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents` (see [Lambda CloudWatch Logs](https://docs.aws.amazon.com/lambda/latest/dg/monitoring-cloudwatchlogs.html)). Without these, logging fails.
2. **S3 (least-privilege)** — Read from the raw bucket/prefix and write to the processed bucket/prefix. Permissions should be scoped with **object-level ARNs** and key prefixes (see [S3 identity policy examples](https://docs.aws.amazon.com/AmazonS3/latest/userguide/example-policies-s3.html)). Our **iam-runtime** module creates a Lambda role with exactly these scopes.

## Optional log retention

If `log_retention_days > 0`, the module creates a **CloudWatch Log Group** named `/aws/lambda/<function_name>` with that retention. This is only for retention; the execution role still must have the Logs permissions above so Lambda can write to the group.

## Usage

```hcl
module "transformer" {
  source = "../../modules/lambda-fn"

  function_name  = "example-transformer"
  role_arn       = module.iam_runtime.lambda_role_arn  # from iam-runtime module
  package_source = "local"
  filename       = "artifacts/transformer.zip"

  runtime = "python3.12"
  handler = "app.handler"

  environment = {
    RAW_BUCKET       = "my-raw-bucket"
    RAW_PREFIX       = "raw/"
    PROCESSED_BUCKET = "my-processed-bucket"
    PROCESSED_PREFIX = "processed/"
  }

  log_retention_days = 14
}
```

## Inputs

| Name | Type | Default | Description |
| ---- | ---- | ------- | ----------- |
| `function_name` | `string` | (required) | Name of the Lambda function. |
| `role_arn` | `string` | (required) | ARN of the Lambda execution role. |
| `package_source` | `string` | (required) | `"s3"` or `"local"`. |
| `s3_bucket` | `string` | `null` | Required when `package_source = "s3"`. |
| `s3_key` | `string` | `null` | Required when `package_source = "s3"`. |
| `filename` | `string` | `null` | Required when `package_source = "local"`. |
| `runtime` | `string` | (required) | e.g. `python3.12`. |
| `handler` | `string` | (required) | e.g. `app.handler`. |
| `timeout` | `number` | `60` | Timeout in seconds. |
| `memory_size` | `number` | `256` | Memory in MB. |
| `environment` | `map(string)` | `{}` | Environment variables. |
| `log_retention_days` | `number` | `0` | If > 0, create log group with this retention. |
| `tags` | `map(string)` | `{}` | Tags merged onto the function. |

## Outputs

| Name | Description |
| ---- | ----------- |
| `function_name` | Lambda function name. |
| `function_arn` | Lambda function ARN. |

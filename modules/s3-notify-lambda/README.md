# s3-notify-lambda

Terraform module that configures **S3 bucket notifications** so that object-created events (with an optional prefix/suffix filter) invoke one or more **Lambda functions**. It creates the required **Lambda permissions** so S3 can invoke the functions and manages **all** Lambda destinations in **one** `aws_s3_bucket_notification` resource.

## Requirements

- Terraform `>= 1.5.0`
- AWS provider `>= 5.0`

## Single notification configuration per bucket

An S3 bucket has **one** notification configuration. If you use multiple `aws_s3_bucket_notification` resources for the same bucket, they will overwrite each other and cause perpetual diffs. This module therefore accepts either a **single** Lambda ARN or a **list** of Lambda destinations and configures **all** of them in a **single** resource. See the [provider docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) and [S3 Event Notifications](https://docs.aws.amazon.com/AmazonS3/latest/userguide/EventNotifications.html).

## Lambda permission

S3 can invoke a Lambda only if the function’s resource policy allows it. For each Lambda target, this module creates an **aws_lambda_permission** with:

- **Principal**: `s3.amazonaws.com`
- **Source ARN**: the bucket ARN (`var.bucket_arn`)

You must pass both `bucket_id` and `bucket_arn` so the notification and the permission can be created correctly.

## Usage

### Single Lambda destination

```hcl
module "raw_notify" {
  source = "../../modules/s3-notify-lambda"

  bucket_id             = "my-raw-bucket"
  bucket_arn            = "arn:aws:s3:::my-raw-bucket"
  lambda_function_arn   = "arn:aws:lambda:us-east-1:123456789012:function:transformer"
  default_prefix_filter = "raw/"
  events                = ["s3:ObjectCreated:*"]
}
```

### Multiple Lambda destinations (one notification resource)

```hcl
module "raw_notify" {
  source = "../../modules/s3-notify-lambda"

  bucket_id  = "my-raw-bucket"
  bucket_arn = "arn:aws:s3:::my-raw-bucket"

  lambda_functions = [
    { arn = "arn:aws:lambda:...:function:transformer", prefix = "raw/" },
    { arn = "arn:aws:lambda:...:function:audit", prefix = "raw/", suffix = ".json" }
  ]
  default_prefix_filter = "raw/"
  events                = ["s3:ObjectCreated:*"]
}
```

### Optional EventBridge

Set `enable_eventbridge = true` to enable S3 events to EventBridge in addition to Lambda (EventBridge configuration is managed separately by AWS).

## Inputs

| Name | Type | Default | Description |
| ---- | ---- | ------- | ----------- |
| `bucket_id` | `string` | (required) | S3 bucket name/id. |
| `bucket_arn` | `string` | (required) | S3 bucket ARN (for Lambda permission source_arn). |
| `lambda_function_arn` | `string` | `null` | Single Lambda ARN. Use this **or** `lambda_functions`. |
| `lambda_functions` | `list(object)` | `null` | List of `{ arn, prefix?, suffix? }`. Use this **or** `lambda_function_arn`. |
| `default_prefix_filter` | `string` | `"raw/"` | Default key prefix when a destination omits `prefix`. |
| `events` | `list(string)` | `["s3:ObjectCreated:*"]` | S3 event types. |
| `enable_eventbridge` | `bool` | `false` | Enable EventBridge for this bucket. |
| `tags` | `map(string)` | `{}` | Tags (documentation; notification resource has limited tag support). |

## Outputs

| Name | Description |
| ---- | ----------- |
| `configured_lambda_count` | Number of Lambda functions in the notification config. |
| `bucket_id` | The bucket id. |

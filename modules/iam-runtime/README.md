# iam-runtime

Terraform module that creates **three IAM roles** for a scraper pipeline: **ECS Fargate** (task + execution roles) and **Lambda** (execution role), with least-privilege S3 access by prefix and correct trust policies.

## Requirements

- Terraform `>= 1.5.0`
- AWS provider `>= 5.0`

## Two ECS roles (and why both exist)

ECS uses **two** roles for Fargate/task execution:

1. **Task execution role** — Used by the **ECS agent** (not your container). It needs permission to pull the container image from ECR and to write logs to CloudWatch Logs. This module attaches the AWS managed policy **AmazonECSTaskExecutionRolePolicy** to this role.  
   [Task execution IAM role](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html)

2. **Task role** — Assumed by your **application code** inside the container at runtime. It should have only the permissions your app needs (e.g. S3 write to the raw prefix). This module grants **s3:PutObject** and **s3:AbortMultipartUpload** on the raw bucket/prefix only.  
   [Task IAM roles](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html)

Both ECS roles use a trust policy with principal **ecs-tasks.amazonaws.com**.

## Lambda execution role

The Lambda role is assumed by the **Lambda service** when running your function. It needs:

- **S3**: **s3:GetObject** on the raw bucket/prefix (read raw data) and **s3:PutObject** (and **s3:AbortMultipartUpload**) on the processed bucket/prefix (write results). Permissions are scoped with **object-level ARNs** (`bucket_arn/prefix*`) for least privilege.  
  [Lambda execution role](https://docs.aws.amazon.com/lambda/latest/dg/lambda-intro-execution-role.html)

- **CloudWatch Logs**: **logs:CreateLogGroup**, **logs:CreateLogStream**, **logs:PutLogEvents** so Lambda can create and write to log streams. You can either use an **inline policy** (default) or attach the AWS managed policy **AWSLambdaBasicExecutionRole** by setting `attach_lambda_basic_logs_managed_policy = true`.  
  [Lambda CloudWatch Logs](https://docs.aws.amazon.com/lambda/latest/dg/monitoring-cloudwatchlogs.html)

Trust policy principal: **lambda.amazonaws.com**.

## Least privilege and S3 prefixes

All S3 permissions use **object-level ARNs** in the form `bucket_arn/prefix*` (e.g. `arn:aws:s3:::my-bucket/raw/*`), so access is limited to the specified prefixes rather than the whole bucket.  
[Example S3 policies](https://docs.aws.amazon.com/AmazonS3/latest/userguide/example-policies-s3.html)

## Usage

```hcl
module "iam_runtime" {
  source = "../../modules/iam-runtime"

  names_prefix  = "prices-scraper"
  raw_bucket_arn       = "arn:aws:s3:::my-raw-bucket"
  raw_prefix           = "raw/"
  processed_bucket_arn = "arn:aws:s3:::my-processed-bucket"
  processed_prefix     = "csv/"

  # Use inline CloudWatch Logs policy (default) or AWS managed AWSLambdaBasicExecutionRole
  attach_lambda_basic_logs_managed_policy = false

  tags = { Project = "scraper" }
}

output "ecs_task_role_arn"       { value = module.iam_runtime.ecs_task_role_arn }
output "ecs_execution_role_arn"  { value = module.iam_runtime.ecs_execution_role_arn }
output "lambda_role_arn"         { value = module.iam_runtime.lambda_role_arn }
```

## Inputs

| Name | Type | Default | Description |
| ---- | ---- | ------- | ----------- |
| `names_prefix` | `string` | (required) | Base name for roles and policies. |
| `raw_bucket_arn` | `string` | (required) | ARN of the raw S3 bucket. |
| `raw_prefix` | `string` | (required) | Object key prefix for raw data (e.g. `raw/`). |
| `processed_bucket_arn` | `string` | (required) | ARN of the processed S3 bucket. |
| `processed_prefix` | `string` | (required) | Object key prefix for processed output (e.g. `csv/`). |
| `attach_lambda_basic_logs_managed_policy` | `bool` | `false` | If true, attach AWSLambdaBasicExecutionRole to Lambda role; else use inline logs policy. |
| `tags` | `map(string)` | `{}` | Tags merged onto all IAM resources. |

## Outputs

| Name | Description |
| ---- | ----------- |
| `ecs_task_role_arn` | ARN of the ECS task role. |
| `ecs_execution_role_arn` | ARN of the ECS task execution role. |
| `lambda_role_arn` | ARN of the Lambda execution role. |

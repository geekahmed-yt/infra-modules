terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  description = "AWS region (e.g. us-east-1)."
  type        = string
  default     = "us-east-1"
}

module "iam_runtime" {
  source = "../../modules/iam-runtime"

  names_prefix         = "prices-scraper"
  raw_bucket_arn       = "arn:aws:s3:::REPLACE-RAW"
  raw_prefix           = "raw/"
  processed_bucket_arn = "arn:aws:s3:::REPLACE-PROCESSED"
  processed_prefix     = "csv/"

  attach_lambda_basic_logs_managed_policy = false
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role."
  value       = module.iam_runtime.ecs_task_role_arn
}

output "ecs_execution_role_arn" {
  description = "ARN of the ECS task execution role."
  value       = module.iam_runtime.ecs_execution_role_arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role."
  value       = module.iam_runtime.lambda_role_arn
}

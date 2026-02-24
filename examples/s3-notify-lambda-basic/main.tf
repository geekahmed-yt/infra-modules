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

module "s3_notify_lambda" {
  source = "../../modules/s3-notify-lambda"

  bucket_id             = "replace-raw-bucket"
  bucket_arn            = "arn:aws:s3:::replace-raw-bucket"
  lambda_function_arn   = "arn:aws:lambda:us-east-1:123456789012:function:example-transformer"
  default_prefix_filter = "raw/"
  events                = ["s3:ObjectCreated:*"]
}

output "configured_lambda_count" {
  description = "Number of Lambda functions configured for the bucket notification."
  value       = module.s3_notify_lambda.configured_lambda_count
}

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

module "lambda" {
  source = "../../modules/lambda-fn"

  function_name  = "example-transformer"
  role_arn       = "arn:aws:iam::REPLACE-ACCOUNT:role/REPLACE-LAMBDA-ROLE"
  package_source = "local"
  filename       = "artifacts/transformer.zip"

  runtime = "python3.12"
  handler = "app.handler"

  environment = {
    RAW_BUCKET       = "replace"
    RAW_PREFIX       = "raw/"
    PROCESSED_BUCKET = "replace"
    PROCESSED_PREFIX = "processed/"
  }
}

output "function_arn" {
  description = "ARN of the Lambda function."
  value       = module.lambda.function_arn
}

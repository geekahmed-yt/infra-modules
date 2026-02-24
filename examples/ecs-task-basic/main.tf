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

variable "image_tag" {
  description = "Image tag to deploy (e.g. git SHA)."
  type        = string
  default     = "latest"
}

module "ecs_task" {
  source = "../../modules/ecs-task"

  name           = "scraper-task"
  cluster_name   = "scraper-cluster"
  container_name = "scraper"
  image_uri      = "123456789012.dkr.ecr.us-east-1.amazonaws.com/scraper:${var.image_tag}"

  cpu    = 512
  memory = 1024

  execution_role_arn = "arn:aws:iam::123456789012:role/REPLACE-EXECUTION-ROLE"
  task_role_arn      = "arn:aws:iam::123456789012:role/REPLACE-TASK-ROLE"

  environment = {
    WRITE_TO_S3 = "true"
    RAW_BUCKET  = "replace"
    RAW_PREFIX  = "raw/"
    AWS_REGION  = var.region
  }

  create_log_group   = true
  log_retention_days = 14

  # Private networking for one-off Fargate tasks
  subnet_ids         = ["subnet-REPLACE-PRIVATE-1", "subnet-REPLACE-PRIVATE-2"]
  security_group_ids = ["sg-REPLACE-OUTBOUND"]
}

output "run_task_cli_example" {
  description = "Example aws ecs run-task CLI command."
  value       = module.ecs_task.run_task_cli_example
}

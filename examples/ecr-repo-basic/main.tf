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

module "ecr" {
  source = "../../modules/ecr-repo"

  repositories = {
    scraper = { tags_prefixes = ["v", "sha-"] }
  }
}

output "repository_urls" {
  description = "Map of repository name to ECR repository URL."
  value       = module.ecr.repository_urls
}

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

module "vpc" {
  source = "../../modules/vpc-minimal"

  name                 = "app-vpc"
  cidr_block           = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  enable_nat_per_az    = true

  create_s3_gateway_endpoint = true
  create_ecr_endpoints       = false
  create_logs_endpoint       = false
  create_secrets_endpoint    = false

  tags = {
    Example = "vpc-minimal-basic"
  }
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.vpc.private_subnet_ids
}

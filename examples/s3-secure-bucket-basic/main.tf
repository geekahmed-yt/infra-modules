terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

module "bucket" {
  source = "../../modules/s3-secure-bucket"

  bucket_name = "example-secure-bucket-${random_id.bucket_suffix.hex}"
  tags = {
    Example = "s3-secure-bucket-basic"
    Purpose = "demonstration"
  }

  # Optional: enable access logging to a central bucket
  # access_log_bucket_id = "my-central-logs-bucket"
  # access_log_prefix    = "s3/example/"
}

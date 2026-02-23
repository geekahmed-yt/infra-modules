variable "name" {
  description = "Prefix for resource names (e.g. app-vpc)."
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR block (e.g. 10.0.0.0/16)."
  type        = string
}

variable "azs" {
  description = "List of exactly two availability zone IDs (e.g. [\"us-east-1a\", \"us-east-1b\"])."
  type        = list(string)

  validation {
    condition     = length(var.azs) == 2
    error_message = "azs must contain exactly two availability zones."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets; length must match azs."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.azs)
    error_message = "public_subnet_cidrs length must match azs."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets; length must match azs."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.azs)
    error_message = "private_subnet_cidrs length must match azs."
  }
}

variable "enable_nat_per_az" {
  description = "When true, create one NAT Gateway per AZ in the public subnets."
  type        = bool
  default     = true
}

variable "create_s3_gateway_endpoint" {
  description = "Create VPC gateway endpoint for S3 (attached to private route tables)."
  type        = bool
  default     = true
}

variable "create_ecr_endpoints" {
  description = "Create VPC interface endpoints for ECR (api and dkr)."
  type        = bool
  default     = false
}

variable "create_logs_endpoint" {
  description = "Create VPC interface endpoint for CloudWatch Logs."
  type        = bool
  default     = false
}

variable "create_secrets_endpoint" {
  description = "Create VPC interface endpoint for Secrets Manager."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to supported resources."
  type        = map(string)
  default     = {}
}

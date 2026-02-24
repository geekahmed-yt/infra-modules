variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "role_arn" {
  description = "ARN of the Lambda execution role (must include CloudWatch Logs and S3 permissions)."
  type        = string
}

variable "package_source" {
  description = "Source of the deployment package: \"s3\" (use s3_bucket + s3_key) or \"local\" (use filename)."
  type        = string

  validation {
    condition     = contains(["s3", "local"], var.package_source)
    error_message = "package_source must be \"s3\" or \"local\"."
  }
}

variable "s3_bucket" {
  description = "S3 bucket containing the deployment package. Required when package_source = \"s3\"."
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key of the deployment package. Required when package_source = \"s3\"."
  type        = string
  default     = null
}

variable "filename" {
  description = "Path to the local zip file. Required when package_source = \"local\"."
  type        = string
  default     = null
}

variable "runtime" {
  description = "Lambda runtime identifier (e.g. python3.12)."
  type        = string
}

variable "handler" {
  description = "Lambda handler entrypoint (e.g. app.handler)."
  type        = string
}

variable "timeout" {
  description = "Function timeout in seconds."
  type        = number
  default     = 60
}

variable "memory_size" {
  description = "Function memory size in MB."
  type        = number
  default     = 256
}

variable "environment" {
  description = "Environment variables for the function (e.g. RAW_BUCKET, RAW_PREFIX, PROCESSED_BUCKET, PROCESSED_PREFIX)."
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "If > 0, create and manage a CloudWatch Log Group for this function with this retention in days."
  type        = number
  default     = 0
}

variable "tags" {
  description = "Tags to merge onto the Lambda function."
  type        = map(string)
  default     = {}
}

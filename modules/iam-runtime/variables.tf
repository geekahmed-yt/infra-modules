variable "names_prefix" {
  description = "Base name for roles and policies (e.g. prices-scraper)."
  type        = string
}

variable "raw_bucket_arn" {
  description = "ARN of the raw S3 bucket (e.g. arn:aws:s3:::my-raw-bucket)."
  type        = string
}

variable "raw_prefix" {
  description = "Object key prefix for raw data (e.g. raw/)."
  type        = string
}

variable "processed_bucket_arn" {
  description = "ARN of the processed S3 bucket."
  type        = string
}

variable "processed_prefix" {
  description = "Object key prefix for processed output (e.g. csv/)."
  type        = string
}

variable "attach_lambda_basic_logs_managed_policy" {
  description = "If true, attach AWS managed policy AWSLambdaBasicExecutionRole to Lambda role; otherwise use inline CloudWatch Logs policy."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to merge onto all created IAM resources."
  type        = map(string)
  default     = {}
}

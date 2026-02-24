variable "bucket_id" {
  description = "S3 bucket name/id."
  type        = string
}

variable "bucket_arn" {
  description = "S3 bucket ARN (used for Lambda permission source_arn)."
  type        = string
}

variable "lambda_function_arn" {
  description = "Single Lambda function ARN to invoke. Use this OR lambda_functions, not both."
  type        = string
  default     = null

  validation {
    condition = (
      (var.lambda_function_arn != null && var.lambda_function_arn != "" && (var.lambda_functions == null || length(var.lambda_functions) == 0)) ||
      (var.lambda_functions != null && length(var.lambda_functions) > 0 && (var.lambda_function_arn == null || var.lambda_function_arn == ""))
    )
    error_message = "Set exactly one of lambda_function_arn (single destination) or lambda_functions (list)."
  }
}

variable "lambda_functions" {
  description = "Multiple Lambda destinations (prefix/suffix per destination). Use this OR lambda_function_arn, not both."
  type = list(object({
    arn    = string
    prefix = optional(string)
    suffix = optional(string)
  }))
  default = null
}

variable "default_prefix_filter" {
  description = "Default object key prefix filter when a destination omits prefix (e.g. raw/)."
  type        = string
  default     = "raw/"
}

variable "events" {
  description = "S3 event types that trigger the notification (e.g. s3:ObjectCreated:*)."
  type        = list(string)
  default     = ["s3:ObjectCreated:*"]
}

variable "enable_eventbridge" {
  description = "If true, enable EventBridge for this bucket (alongside Lambda targets)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags (for documentation; S3 bucket notification has limited tag support)."
  type        = map(string)
  default     = {}
}

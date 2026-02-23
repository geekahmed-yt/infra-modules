variable "bucket_name" {
  type = string
}
variable "force_destroy" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}

variable "object_ownership_mode" {
  type    = string
  default = "BucketOwnerEnforced"
}

variable "block_public_access" {
  type    = bool
  default = true
}

variable "sse_mode" {
  type    = string
  default = "SSE-S3"
  validation {
    condition     = contains(["SSE-S3", "SSE-KMS"], var.sse_mode)
    error_message = "sse_mode must be SSE-S3 or SSE-KMS"
  }
}
variable "kms_key_arn" {
  type    = string
  default = null
}
variable "bucket_key_enabled" {
  type    = bool
  default = true
}

variable "enable_versioning" {
  type    = bool
  default = true
}
variable "enable_abort_incomplete_mpu" {
  type    = bool
  default = true
}
variable "abort_incomplete_mpu_after_days" {
  type    = number
  default = 7
}

variable "enforce_tls_only" {
  type    = bool
  default = true
}

variable "access_log_bucket_id" {
  type    = string
  default = null
}
variable "access_log_prefix" {
  type    = string
  default = "logs/"
}
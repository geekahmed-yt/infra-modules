output "configured_lambda_count" {
  description = "Number of Lambda functions configured to be invoked by this bucket's notification."
  value       = length(local.destinations)
}

output "bucket_id" {
  description = "S3 bucket id (name) that has the notification configuration."
  value       = var.bucket_id
}

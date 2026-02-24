# Normalize to a list of destinations so we manage one notification config and one permission per Lambda.
# S3 supports a single notification configuration per bucket; all Lambda targets must be in one resource.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification
locals {
  destinations = var.lambda_function_arn != null && var.lambda_function_arn != "" ? [
    { arn = var.lambda_function_arn, prefix = var.default_prefix_filter, suffix = null }
    ] : [for d in var.lambda_functions : {
      arn    = d.arn
      prefix = coalesce(d.prefix, var.default_prefix_filter)
      suffix = d.suffix
  }]
}

# One Lambda permission per destination so S3 can invoke the function (principal s3.amazonaws.com, source_arn = bucket).
resource "aws_lambda_permission" "allow_s3" {
  for_each = { for i, d in local.destinations : i => d }

  statement_id  = "AllowS3Invoke-${var.bucket_id}-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.arn
  principal     = "s3.amazonaws.com"
  source_arn    = var.bucket_arn
}

# Single notification configuration for the bucket; all Lambda destinations in one resource to avoid overwrites.
# https://docs.aws.amazon.com/AmazonS3/latest/userguide/EventNotifications.html
resource "aws_s3_bucket_notification" "this" {
  bucket = var.bucket_id

  eventbridge = var.enable_eventbridge

  dynamic "lambda_function" {
    for_each = local.destinations
    content {
      lambda_function_arn = lambda_function.value.arn
      events              = var.events
      filter_prefix       = lambda_function.value.prefix
      filter_suffix       = lambda_function.value.suffix
    }
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# Optional CloudWatch Log Group (retention only; permissions are on the execution role)
# https://docs.aws.amazon.com/lambda/latest/dg/monitoring-cloudwatchlogs.html
resource "aws_cloudwatch_log_group" "this" {
  count = var.log_retention_days > 0 ? 1 : 0

  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = var.role_arn
  runtime       = var.runtime
  handler       = var.handler
  timeout       = var.timeout
  memory_size   = var.memory_size

  dynamic "environment" {
    for_each = length(var.environment) > 0 ? [1] : []
    content {
      variables = var.environment
    }
  }

  s3_bucket        = var.package_source == "s3" ? var.s3_bucket : null
  s3_key           = var.package_source == "s3" ? var.s3_key : null
  filename         = var.package_source == "local" ? var.filename : null
  source_code_hash = var.package_source == "local" ? filebase64sha256(var.filename) : null

  tags = merge(var.tags, { Module = "lambda-fn" })
}

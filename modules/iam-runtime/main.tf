locals {
  tags = merge(var.tags, { Module = "iam-runtime" })
  # Object-level ARNs for S3: bucket ARN + "/" + key prefix + "*"
  raw_objects_arn       = "${var.raw_bucket_arn}/${var.raw_prefix}*"
  processed_objects_arn = "${var.processed_bucket_arn}/${var.processed_prefix}*"
}

# -----------------------------------------------------------------------------
# ECS Task Role (application permissions: write to raw prefix)
# Trust: ecs-tasks.amazonaws.com
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html
# -----------------------------------------------------------------------------
resource "aws_iam_role" "ecs_task" {
  name = "${var.names_prefix}-ecs-task"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
  tags = local.tags
}

resource "aws_iam_role_policy" "ecs_task_write_raw" {
  name = "WriteRawPrefix"
  role = aws_iam_role.ecs_task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject", "s3:AbortMultipartUpload"]
      Resource = local.raw_objects_arn
    }]
  })
}

# -----------------------------------------------------------------------------
# ECS Task Execution Role (agent: ECR pull, CloudWatch Logs)
# Trust: ecs-tasks.amazonaws.com
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
# https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonECSTaskExecutionRolePolicy.html
# -----------------------------------------------------------------------------
resource "aws_iam_role" "ecs_execution" {
  name = "${var.names_prefix}-ecs-execution"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -----------------------------------------------------------------------------
# Lambda Execution Role (read raw, write processed, CloudWatch Logs)
# Trust: lambda.amazonaws.com
# https://docs.aws.amazon.com/lambda/latest/dg/lambda-intro-execution-role.html
# https://docs.aws.amazon.com/lambda/latest/dg/monitoring-cloudwatchlogs.html
# -----------------------------------------------------------------------------
resource "aws_iam_role" "lambda" {
  name = "${var.names_prefix}-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
  tags = local.tags
}

# S3: GetObject on raw prefix, PutObject + AbortMultipartUpload on processed prefix
resource "aws_iam_role_policy" "lambda_s3" {
  name = "S3RawProcessed"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = local.raw_objects_arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:AbortMultipartUpload", "s3:GetObject", "s3:ListBucket"]
        Resource = local.processed_objects_arn
      }
    ]
  })
}

# CloudWatch Logs: inline or managed per var.attach_lambda_basic_logs_managed_policy
resource "aws_iam_role_policy" "lambda_logs" {
  count = var.attach_lambda_basic_logs_managed_policy ? 0 : 1

  name = "CloudWatchLogs"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  count = var.attach_lambda_basic_logs_managed_policy ? 1 : 0

  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

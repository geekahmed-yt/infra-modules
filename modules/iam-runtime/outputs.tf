output "ecs_task_role_arn" {
  description = "ARN of the ECS task role (application permissions, e.g. S3 write to raw prefix)."
  value       = aws_iam_role.ecs_task.arn
}

output "ecs_execution_role_arn" {
  description = "ARN of the ECS task execution role (ECR pull, CloudWatch Logs)."
  value       = aws_iam_role.ecs_execution.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role (S3 raw/processed, CloudWatch Logs)."
  value       = aws_iam_role.lambda.arn
}

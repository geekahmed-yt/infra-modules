output "cluster_arn" {
  description = "ARN of the ECS cluster."
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition."
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_family" {
  description = "Family of the ECS task definition."
  value       = aws_ecs_task_definition.this.family
}

output "log_group_name" {
  description = "Name of the CloudWatch Logs log group (whether created by this module or pre-existing)."
  value       = local.effective_log_group
}

locals {
  run_task_network_config = jsonencode({
    awsvpcConfiguration = {
      subnets        = var.subnet_ids
      securityGroups = var.security_group_ids
      assignPublicIp = "DISABLED"
    }
  })
}

output "run_task_cli_example" {
  description = "Example aws ecs run-task CLI command for this task using the provided private subnet_ids and security_group_ids."
  value       = <<-EOT
aws ecs run-task \
  --cluster ${aws_ecs_cluster.this.name} \
  --task-definition ${aws_ecs_task_definition.this.family} \
  --launch-type FARGATE \
  --count 1 \
  --network-configuration '${local.run_task_network_config}' \
  --platform-version ${var.platform_version}
EOT
}

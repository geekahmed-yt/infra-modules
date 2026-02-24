data "aws_region" "current" {}

locals {
  effective_cluster_name = coalesce(var.cluster_name, "${var.name}-cluster")
  effective_log_group    = coalesce(var.log_group_name, "/ecs/${var.name}")

  container_def_base = {
    name      = var.container_name
    image     = var.image_uri
    essential = true

    command = var.command

    environment = length(var.environment) > 0 ? [
      for k, v in var.environment : {
        name  = k
        value = v
      }
    ] : null

    secrets      = length(var.secrets) > 0 ? var.secrets : null
    portMappings = length(var.port_mappings) > 0 ? var.port_mappings : null

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = local.effective_log_group
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = var.log_stream_prefix
      }
    }
  }

  container_def = {
    for k, v in local.container_def_base : k => v if v != null
  }
}

resource "aws_ecs_cluster" "this" {
  name = local.effective_cluster_name

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "this" {
  count = var.create_log_group ? 1 : 0

  name = local.effective_log_group

  lifecycle {
    prevent_destroy = false
  }

  retention_in_days = var.log_retention_days > 0 ? var.log_retention_days : null
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    local.container_def
  ])

  tags = var.tags
}

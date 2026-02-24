variable "name" {
  description = "Base name for ECS resources (cluster, task family, log group)."
  type        = string
}

variable "tags" {
  description = "Tags applied to ECS resources."
  type        = map(string)
  default     = {}
}

variable "container_name" {
  description = "Name of the container in the task definition."
  type        = string
}

variable "image_uri" {
  description = "Container image URI (e.g. ECR image)."
  type        = string
}

variable "cpu" {
  description = "Fargate CPU units (e.g. 256, 512, 1024)."
  type        = number
}

variable "memory" {
  description = "Fargate memory in MiB (e.g. 512, 1024, 2048)."
  type        = number
}

variable "platform_version" {
  description = "Fargate platform version (e.g. 1.4.0 or LATEST)."
  type        = string
  default     = "LATEST"
}

variable "execution_role_arn" {
  description = "IAM role ARN used as the ECS task execution role (ECR pull + CloudWatch Logs)."
  type        = string
}

variable "task_role_arn" {
  description = "IAM role ARN used as the ECS task role (application permissions, e.g. S3)."
  type        = string
}

variable "command" {
  description = "Optional container command override."
  type        = list(string)
  default     = null
}

variable "environment" {
  description = "Environment variables for the container."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secrets for the container (name/valueFrom ARNs)."
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "port_mappings" {
  description = "Optional port mappings for the container."
  type = list(object({
    containerPort = number
    hostPort      = number
    protocol      = string
  }))
  default = []
}

variable "create_log_group" {
  description = "Whether to create the CloudWatch Logs log group."
  type        = bool
  default     = true
}

variable "log_group_name" {
  description = "Name of the CloudWatch Logs log group. If null, defaults to /ecs/<name>."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "If > 0, set retention on the log group (when created)."
  type        = number
  default     = 0
}

variable "log_stream_prefix" {
  description = "Prefix for CloudWatch Logs streams created by the awslogs driver."
  type        = string
  default     = "ecs"
}

variable "cluster_name" {
  description = "Name of the ECS cluster. If null, defaults to <name>-cluster."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Private subnet IDs where one-off Fargate tasks will run (used in run-task CLI example)."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs to attach to the task ENI (typically outbound-only, used in run-task CLI example)."
  type        = list(string)
}

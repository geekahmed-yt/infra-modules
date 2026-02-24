# ecs-task

Terraform module that creates an **ECS Fargate cluster**, a **single-container task definition**, and an optional **CloudWatch Logs log group** for running **one-off tasks** via `aws ecs run-task`. It does **not** create an ECS service or any schedules.

## Requirements

- Terraform `>= 1.5.0`
- AWS provider `>= 5.0`

## What this module creates

- **ECS cluster** (Fargate-capable) with a configurable name.
- **ECS task definition** for a **single container**:
  - `network_mode = "awsvpc"` and `requires_compatibilities = ["FARGATE"]`.
  - CPU and memory sized for Fargate (you must choose a valid pair; see [Fargate task sizing](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html)).
  - Uses a provided **execution role ARN** (for ECR pulls + CloudWatch Logs) and **task role ARN** (application permissions, e.g. S3) — typically from an `iam-runtime` module.
  - Container uses the **awslogs** log driver to send stdout/stderr to CloudWatch Logs.  
    [awslogs log driver](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_awslogs.html)
- **CloudWatch Logs log group** (optional): `/ecs/<name>` by default; optional retention in days.

## What this module does **not** create

- **ECS service** (no long-running service or autoscaling).
- **EventBridge rules** or schedules.  

This module is designed for **one-off / ad-hoc Fargate tasks** triggered externally (typically from CI) using `aws ecs run-task`.  
[RunTask API / CLI](https://docs.aws.amazon.com/cli/latest/reference/ecs/run-task.html)

## Networking and Fargate

Tasks use `network_mode = "awsvpc"`, which gives each Fargate task its own **ENI** in your VPC. When you call `aws ecs run-task` you must provide:

- **subnets** (usually **private** subnets for outbound-only workloads).
- **security groups** (typically outbound-only group, e.g., to reach S3/ECR via NAT or VPC endpoints).

If you place tasks in **private subnets**, you must provide **NAT** (or VPC interface endpoints for ECR and CloudWatch Logs, plus a gateway endpoint for S3) so that the task can:

- Pull the container image from ECR.
- Write logs to CloudWatch Logs.
- Reach AWS APIs (e.g., S3, Secrets Manager).  
[Fargate task networking](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-task-networking.html)

## Logging

The module configures the container to use the **awslogs** driver:

- `awslogs-group` — points to the CloudWatch Logs log group (created or pre-existing).
- `awslogs-region` — current AWS region.
- `awslogs-stream-prefix` — configurable via `log_stream_prefix` (default: `ecs`).

You can opt in to log group creation and retention with `create_log_group` and `log_retention_days`. The **execution role** must have the usual CloudWatch Logs permissions.

## Inputs (key fields)

- `name` — base name for cluster, task family, and default log group.
- `container_name` — container name in the task definition.
- `image_uri` — fully qualified image URI (e.g. ECR).
- `cpu`, `memory` — Fargate task size (valid combinations only).
- `execution_role_arn` — ECS task execution role ARN (ECR + logs).
- `task_role_arn` — ECS task role ARN (app permissions).
- `environment`, `secrets`, `port_mappings` — container configuration.
- `create_log_group`, `log_retention_days`, `log_group_name`, `log_stream_prefix` — logging configuration.
- `cluster_name` — optional override of cluster name.

## Outputs

- `cluster_arn`, `cluster_name` — ECS cluster.
- `task_definition_arn`, `task_definition_family` — task definition identifiers.
- `log_group_name` — CloudWatch Logs log group name.
- `run_task_cli_example` — ready-to-copy `aws ecs run-task` command (fill in actual subnets and security groups).

## Triggering one-off tasks from CI

Typical pattern:

1. **Assume an IAM role** via OIDC in your CI pipeline (for example, using `aws-actions/configure-aws-credentials` in GitHub Actions).
2. **Run the CLI command** from the `run_task_cli_example` output, replacing:
   - `subnet-XXXX`, `subnet-YYYY` with your private subnet IDs.
   - `sg-AAAA` with your security group ID.
3. Optionally add `--overrides` with `containerOverrides` if you need to change the container command or environment for a specific run. See the [ECS RunTask docs](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_AWSCLI_Fargate.html) for examples.

Example (simplified) CLI snippet:

```bash
aws ecs run-task \
  --cluster <cluster_name> \
  --task-definition <task_family> \
  --launch-type FARGATE \
  --count 1 \
  --network-configuration '{
    "awsvpcConfiguration": {
      "subnets": ["subnet-XXXX", "subnet-YYYY"],
      "securityGroups": ["sg-AAAA"],
      "assignPublicIp": "DISABLED"
    }
  }' \
  --platform-version LATEST
```

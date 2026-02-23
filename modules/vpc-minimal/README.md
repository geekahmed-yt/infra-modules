# vpc-minimal

Terraform module that creates a **minimal, production-sane VPC** with **outbound-only internet** for workloads in private subnets. Public subnets host NAT Gateways and route to an Internet Gateway (IGW); private subnets route only to the NAT in the same AZ, not to the IGW.

## Requirements

| Name      | Version   |
| --------- | --------- |
| terraform | `>= 1.5.0` |
| aws       | `>= 5.0`  |

## What this module creates

- **VPC** with DNS support and DNS hostnames enabled.
- **Internet Gateway (IGW)** attached to the VPC.
- **Two public subnets** (one per AZ): `map_public_ip_on_launch = true`, single route table with default route `0.0.0.0/0` → IGW. Used to host NAT Gateways.
- **Two private subnets** (one per AZ): no direct route to IGW. Each has its own route table with default route `0.0.0.0/0` → NAT Gateway **in the same AZ** when `enable_nat_per_az = true`.
- **NAT Gateways**: one per AZ in the public subnets (configurable via `enable_nat_per_az`). Each private subnet’s default traffic goes to the NAT in its AZ for lower latency and single-AZ failure isolation.
- **Optional VPC endpoints**:
  - **S3 gateway endpoint** (default: enabled): attached to **private** route tables only. S3 traffic from private subnets goes via the endpoint, not NAT, reducing NAT data charges.
  - **Interface endpoints** (default: disabled): ECR (api + dkr), CloudWatch Logs, Secrets Manager. When any are enabled, a shared **endpoint security group** is created with ingress TCP/443 from private subnet CIDRs and egress allow all; interface endpoints are placed in private subnets with this SG and `private_dns_enabled = true`.

## Outbound-only internet (IGW + NAT)

- **Public subnets** have a route to the IGW, so resources there can have public IPs and receive inbound internet traffic.
- **Private subnets** have **no** route to the IGW. Their default route is to a **NAT Gateway** in the same AZ. The NAT Gateway lives in a public subnet and uses the IGW for outbound traffic. As a result:
  - Workloads in private subnets can initiate **outbound** internet (e.g. pull images, call APIs) via NAT.
  - There is **no inbound exposure** from the internet to private subnet resources unless you add other mechanisms (e.g. load balancers in public subnets).

This pattern is standard for ECS/Lambda in private subnets: tasks need egress (e.g. 443) but should not be directly reachable from the internet.

## Cost notes

- **S3 gateway endpoint** is free and keeps S3 traffic off the NAT, reducing NAT data processing charges. It is enabled by default.
- **Interface endpoints** (ECR, Logs, Secrets Manager) have hourly and data costs but can further reduce or eliminate NAT usage for those services. Enable them if you want to minimize NAT traffic or meet compliance requirements.

## Usage (ECS / Lambda)

- Place **tasks or Lambdas in the private subnets** (e.g. `private_subnet_ids` from the module output).
- Use a security group with **egress 443** (and any other required ports); no inbound rules from the internet unless you explicitly add them (e.g. from a load balancer).
- For ECS with ECR: either rely on NAT for ECR access or set `create_ecr_endpoints = true` so ECR traffic stays inside the VPC.

## Inputs

| Name | Type | Default | Description |
| ---- | ---- | ------- | ----------- |
| `name` | `string` | (required) | Prefix for resource names. |
| `cidr_block` | `string` | (required) | VPC CIDR (e.g. `10.0.0.0/16`). |
| `azs` | `list(string)` | (required) | Exactly two AZs (e.g. `["us-east-1a","us-east-1b"]`). |
| `public_subnet_cidrs` | `list(string)` | (required) | CIDRs for public subnets; length must match `azs`. |
| `private_subnet_cidrs` | `list(string)` | (required) | CIDRs for private subnets; length must match `azs`. |
| `enable_nat_per_az` | `bool` | `true` | Create one NAT Gateway per AZ. |
| `create_s3_gateway_endpoint` | `bool` | `true` | Create S3 gateway endpoint on private route tables. |
| `create_ecr_endpoints` | `bool` | `false` | Create ECR api + dkr interface endpoints. |
| `create_logs_endpoint` | `bool` | `false` | Create CloudWatch Logs interface endpoint. |
| `create_secrets_endpoint` | `bool` | `false` | Create Secrets Manager interface endpoint. |
| `tags` | `map(string)` | `{}` | Tags for supported resources. |

## Outputs

| Name | Description |
| ---- | ----------- |
| `vpc_id` | VPC ID. |
| `public_subnet_ids` | List of public subnet IDs. |
| `private_subnet_ids` | List of private subnet IDs. |
| `endpoint_sg_id` | ID of the shared endpoint security group, or `null` if no interface endpoints are enabled. |

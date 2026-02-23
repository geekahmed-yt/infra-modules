# vpc-minimal-basic

Minimal runnable example for the `vpc-minimal` module: one VPC, two public subnets (NAT + IGW), two private subnets (default route to NAT per AZ), and S3 gateway endpoint on private route tables.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Outputs

- `vpc_id` — VPC ID
- `private_subnet_ids` — Two private subnet IDs (one per AZ)

## What gets created

- 1 VPC (DNS support and hostnames enabled)
- 1 Internet Gateway
- 2 public subnets with route table → IGW
- 2 private subnets, each with route table → NAT in same AZ
- 2 EIPs and 2 NAT Gateways (one per AZ)
- S3 gateway endpoint attached to private route tables only

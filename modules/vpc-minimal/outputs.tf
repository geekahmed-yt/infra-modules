output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (one per AZ)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (one per AZ)."
  value       = aws_subnet.private[*].id
}

output "endpoint_sg_id" {
  description = "ID of the shared security group for VPC interface endpoints, or null if no interface endpoints are enabled."
  value       = local.create_interface_endpoints ? aws_security_group.endpoint[0].id : null
}

data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

# -----------------------------------------------------------------------------
# Public subnets (NAT Gateways + route to IGW)
# -----------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count = length(var.azs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-public-${var.azs[count.index]}"
    Tier = "public"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-public"
    Tier = "public"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = length(var.azs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# -----------------------------------------------------------------------------
# Private subnets (workloads; route to NAT per AZ)
# -----------------------------------------------------------------------------
resource "aws_subnet" "private" {
  count = length(var.azs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-private-${var.azs[count.index]}"
    Tier = "private"
  })
}

# NAT: EIP + NAT Gateway per AZ (in public subnet)
resource "aws_eip" "nat" {
  count = var.enable_nat_per_az ? length(var.azs) : 0

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-nat-eip-${var.azs[count.index]}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_per_az ? length(var.azs) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "${var.name}-nat-${var.azs[count.index]}"
  })

  depends_on = [aws_route_table_association.public]
}

# Private route table per AZ: default route to NAT in same AZ
resource "aws_route_table" "private" {
  count = length(var.azs)

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-private-${var.azs[count.index]}"
    Tier = "private"
  })
}

resource "aws_route" "private_nat" {
  count = var.enable_nat_per_az ? length(var.azs) : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

resource "aws_route_table_association" "private" {
  count = length(var.azs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# -----------------------------------------------------------------------------
# S3 Gateway Endpoint (private route tables only)
# -----------------------------------------------------------------------------
resource "aws_vpc_endpoint" "s3" {
  count = var.create_s3_gateway_endpoint ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id

  tags = merge(var.tags, {
    Name = "${var.name}-s3-endpoint"
  })
}

# -----------------------------------------------------------------------------
# Endpoint security group (when any interface endpoint is enabled)
# -----------------------------------------------------------------------------
locals {
  create_interface_endpoints = var.create_ecr_endpoints || var.create_logs_endpoint || var.create_secrets_endpoint
}

resource "aws_security_group" "endpoint" {
  count = local.create_interface_endpoints ? 1 : 0

  name_prefix = "${var.name}-endpoint-"
  description = "Security group for VPC interface endpoints; allows HTTPS from private subnets."
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from private subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-endpoint-sg"
  })
}

# -----------------------------------------------------------------------------
# Interface endpoints (ECR api, ECR dkr, Logs, Secrets Manager)
# -----------------------------------------------------------------------------
locals {
  region_suffix       = data.aws_region.current.id
  endpoint_subnet_ids = local.create_interface_endpoints ? aws_subnet.private[*].id : []
  endpoint_sg_ids     = local.create_interface_endpoints ? [aws_security_group.endpoint[0].id] : []
}

resource "aws_vpc_endpoint" "ecr_api" {
  count = var.create_ecr_endpoints ? 1 : 0

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${local.region_suffix}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.endpoint_subnet_ids
  security_group_ids  = local.endpoint_sg_ids
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name}-ecr-api"
  })
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.create_ecr_endpoints ? 1 : 0

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${local.region_suffix}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.endpoint_subnet_ids
  security_group_ids  = local.endpoint_sg_ids
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name}-ecr-dkr"
  })
}

resource "aws_vpc_endpoint" "logs" {
  count = var.create_logs_endpoint ? 1 : 0

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${local.region_suffix}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.endpoint_subnet_ids
  security_group_ids  = local.endpoint_sg_ids
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name}-logs"
  })
}

resource "aws_vpc_endpoint" "secretsmanager" {
  count = var.create_secrets_endpoint ? 1 : 0

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${local.region_suffix}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.endpoint_subnet_ids
  security_group_ids  = local.endpoint_sg_ids
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name}-secretsmanager"
  })
}

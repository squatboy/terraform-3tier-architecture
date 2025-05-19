// vpc.tf

//------------------------------------------------------------------------------
// VPC
//------------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-vpc"
  })
}

//------------------------------------------------------------------------------
// Internet Gateway
//------------------------------------------------------------------------------
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-igw"
  })
}

//------------------------------------------------------------------------------
// Subnets
//------------------------------------------------------------------------------

// Public Subnets (for ALB, NAT Gateways, Bastion Hosts if any)
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones) // Should be 2 based on var.availability_zones validation
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true // Instances in public subnets (like Web Tier if directly public, or NAT GWs)

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-public-subnet-${var.availability_zones[count.index]}"
    Tier = "Public"
  })
}

// Private Subnets for App Tier
resource "aws_subnet" "private_app" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-private-app-subnet-${var.availability_zones[count.index]}"
    Tier = "Application"
  })
}

// Private Subnets for DB/Cache Tier
resource "aws_subnet" "private_db" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_db_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-private-db-subnet-${var.availability_zones[count.index]}"
    Tier = "Database"
  })
}

//------------------------------------------------------------------------------
// NAT Gateways & EIPs
//------------------------------------------------------------------------------

// Elastic IPs for NAT Gateways (one per AZ for HA)
resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc" // For use with NAT Gateway

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-nat-eip-${var.availability_zones[count.index]}"
  })
}

// NAT Gateways (one per AZ, placed in public subnets)
resource "aws_nat_gateway" "nat" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id // NAT GW lives in a public subnet

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-nat-gw-${var.availability_zones[count.index]}"
  })

  depends_on = [aws_internet_gateway.gw] // Ensure IGW is created first
}

//------------------------------------------------------------------------------
// Route Tables
//------------------------------------------------------------------------------

// Route Table for Public Subnets (routes to Internet Gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-public-rt"
  })
}

// Associate Public Route Table with Public Subnets
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

// Route Tables for Private App Subnets (one per AZ, routes to corresponding NAT GW)
resource "aws_route_table" "private_app" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-private-app-rt-${var.availability_zones[count.index]}"
  })
}

// Associate Private App Route Tables with Private App Subnets
resource "aws_route_table_association" "private_app" {
  count          = length(aws_subnet.private_app)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app[count.index].id
}

// Route Tables for Private DB Subnets (one per AZ, routes to corresponding NAT GW)
resource "aws_route_table" "private_db" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-private-db-rt-${var.availability_zones[count.index]}"
  })
}

// Associate Private DB Route Tables with Private DB Subnets
resource "aws_route_table_association" "private_db" {
  count          = length(aws_subnet.private_db)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db[count.index].id
}

// modules/vpc/main.tf

// VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

// Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index % length(var.availability_zones)] // Distribute across AZs
  map_public_ip_on_launch = true                                                                 // Instances in public subnets get public IPs by default

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}

// Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)] // Distribute across AZs

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
  }
}

// Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

// Elastic IP for NAT Gateway (1 per AZ for HA, but 1 for simplicity here)
resource "aws_eip" "nat" {
  count  = length(var.availability_zones) > 0 ? 1 : 0 // Create one EIP if AZs are defined
  domain = "vpc"                                      // This is the new syntax instead of vpc = true
  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

// NAT Gateway (Place in the first public subnet for simplicity)
resource "aws_nat_gateway" "nat" {
  count         = length(var.availability_zones) > 0 ? 1 : 0 // Create one NAT GW
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id // Typically one NAT GW per AZ in production for HA

  tags = {
    Name = "${var.project_name}-nat-gw"
  }

  depends_on = [aws_internet_gateway.gw]
}

// Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

// Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

// Private Route Table (routes to NAT Gateway)
resource "aws_route_table" "private" {
  count  = length(var.availability_zones) > 0 ? 1 : 0 // Create one private RT if NAT GW exists
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

// Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  route_table_id = length(aws_route_table.private) > 0 ? aws_route_table.private[0].id : aws_route_table.public.id // Fallback to public if no NAT
  subnet_id      = aws_subnet.private[count.index].id
}

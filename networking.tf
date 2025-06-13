# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name      = "${var.project}-vpc"
    Project   = var.project
    ManagedBy = "Terraform"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name    = "${var.project}-igw"
    Project = var.project
  }
}

# Public Subnets for ALB
resource "aws_subnet" "public" {
  for_each                = toset(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, index(var.availability_zones, each.key))
  availability_zone       = each.key
  map_public_ip_on_launch = true
  tags = {
    Name    = "${var.project}-public-${each.key}"
    Project = var.project
    Tier    = "public"
  }
}

# Private App Subnets
resource "aws_subnet" "app" {
  for_each          = toset(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, index(var.availability_zones, each.key) + 2)
  availability_zone = each.key
  tags = {
    Name    = "${var.project}-app-${each.key}"
    Project = var.project
    Tier    = "app"
  }
}

# Private Data Subnets
resource "aws_subnet" "data" {
  for_each          = toset(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, index(var.availability_zones, each.key) + 4)
  availability_zone = each.key
  tags = {
    Name    = "${var.project}-data-${each.key}"
    Project = var.project
    Tier    = "data"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name    = "${var.project}-public-rt"
    Project = var.project
  }
}

# Associate public subnets
resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

// main.tf
// Root module configuration.

provider "aws" {
  region = var.aws_region
}

// Data source to get latest Amazon Linux 2 AMI if ami_id_web/app are not set
data "aws_ami" "amazon_linux_2_web" {
  count       = var.ami_id_web == "" ? 1 : 0 # Only run if ami_id_web is not set
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "amazon_linux_2_app" {
  count       = var.ami_id_app == "" ? 1 : 0 # Only run if ami_id_app is not set
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

// Use provided AMI or the one found by data source
locals {
  web_ami_id = var.ami_id_web != "" ? var.ami_id_web : data.aws_ami.amazon_linux_2_web[0].id
  app_ami_id = var.ami_id_app != "" ? var.ami_id_app : data.aws_ami.amazon_linux_2_app[0].id
}

module "vpc" {
  source               = "./modules/vpc"
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  aws_region           = var.aws_region
}

module "security_groups" {
  source       = "./modules/security_groups"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  db_port      = var.db_engine == "mysql" ? 3306 : (var.db_engine == "postgres" ? 5432 : 3306) // Example port logic
}

module "alb" {
  source                = "./modules/alb"
  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  web_security_group_id = module.security_groups.web_sg_id
}

module "web_tier" {
  source             = "./modules/ec2_asg"
  project_name       = var.project_name
  tier_name          = "web"
  ami_id             = local.web_ami_id
  instance_type      = var.web_instance_type
  subnet_ids         = module.vpc.public_subnet_ids // Web tier in public subnets
  security_group_ids = [module.security_groups.web_sg_id]
  target_group_arns  = [module.alb.alb_target_group_arn]
  min_size           = 2
  max_size           = 4
  desired_capacity   = 2
  user_data          = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Web Tier - $(hostname -f)</h1>" > /var/www/html/index.html
              EOF
}

module "app_tier" {
  source             = "./modules/ec2_asg"
  project_name       = var.project_name
  tier_name          = "app"
  ami_id             = local.app_ami_id
  instance_type      = var.app_instance_type
  subnet_ids         = slice(module.vpc.private_subnet_ids, 0, length(var.availability_zones)) // App tier in first set of private subnets
  security_group_ids = [module.security_groups.app_sg_id]
  # target_group_arns = [] # No ALB for app tier in this example, or create an internal ALB
  min_size         = 2
  max_size         = 4
  desired_capacity = 2
  user_data        = <<-EOF
              #!/bin/bash
              yum update -y
              # Add app server installation (e.g., Java, Python, Node.js)
              echo "<h1>App Tier Setup - $(hostname -f)</h1>" > /tmp/app_tier_ready.txt
              EOF
}

module "rds" {
  source               = "./modules/rds"
  project_name         = var.project_name
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_engine            = var.db_engine
  db_engine_version    = var.db_engine_version
  vpc_id               = module.vpc.vpc_id
  # Use the remaining private subnets for DB, ensuring they are in different AZs if possible
  db_subnet_ids        = slice(module.vpc.private_subnet_ids, length(var.availability_zones), length(module.vpc.private_subnet_ids))
  db_security_group_id = module.security_groups.db_sg_id
  availability_zones   = var.availability_zones // For multi_az if enabled
}

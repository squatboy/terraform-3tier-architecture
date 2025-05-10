// variables.tf
// Input variables for the root module.

variable "aws_region" {
  description = "AWS region to deploy resources."
  type        = string
  default     = "ap-northeast-2" // Seoul
}

variable "project_name" {
  description = "A name for the project to prefix resources."
  type        = string
  default     = "my3tier"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (app & db)."
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"] // More subnets for app/db flexibility
}

variable "availability_zones" {
  description = "List of Availability Zones to use."
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"] // Ensure these match your region and subnet count
}

variable "web_instance_type" {
  description = "EC2 instance type for the web tier."
  type        = string
  default     = "t3.micro"
}

variable "app_instance_type" {
  description = "EC2 instance type for the app tier."
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS instance class for the database tier."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB."
  type        = number
  default     = 20
}

variable "db_engine" {
  description = "Database engine for RDS (e.g., mysql, postgres)."
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Database engine version."
  type        = string
  default     = "8.0" // Check AWS for latest supported versions for MySQL
}

variable "db_name" {
  description = "Name for the RDS database."
  type        = string
  default     = "mydb"
}

variable "db_username" {
  description = "Username for the RDS database master user."
  type        = string
  default     = "adminuser"
}

variable "db_password" {
  description = "Password for the RDS database master user. Should be kept secret."
  type        = string
  sensitive   = true
  // Provide this in terraform.tfvars or via environment variable TF_VAR_db_password
}

variable "ami_id_web" {
  description = "AMI ID for Web Tier EC2 instances (e.g., Amazon Linux 2)."
  type        = string
  default     = "" // Example: "ami-0c94855ba95c71c99" - Find latest Amazon Linux 2 AMI for your region
  // Or use data "aws_ami" to find it dynamically
}

variable "ami_id_app" {
  description = "AMI ID for App Tier EC2 instances (e.g., Amazon Linux 2)."
  type        = string
  default     = "" // Example: "ami-0c94855ba95c71c99" - Find latest Amazon Linux 2 AMI for your region
}

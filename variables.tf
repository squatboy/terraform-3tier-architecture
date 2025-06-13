variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "project" {
  description = "Name prefix for all resources"
  type        = string
  default     = "my3tier"
}

variable "domain_name" {
  description = "Public DNS zone (e.g. example.com)"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for CloudFront & ALB"
  type        = string
}

variable "key_name" {
  description = "EC2 KeyPair name for SSH"
  type        = string
}

variable "app_instance_type" {
  description = "EC2 instance type for app servers"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "availability_zones" {
  description = "List of two AZs"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

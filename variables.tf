// variables.tf

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "List of Availability Zones to use (must match diagram/subnet CIDRs and be 2)"
  type        = list(string)
  // Example: default = ["us-east-1a", "us-east-1b"]
  // Ensure the order matches the CIDR assignments in locals.tf
  validation {
    condition     = length(var.availability_zones) == 2 // Based on diagram and subnet design
    error_message = "Exactly two Availability Zones are required for this configuration."
  }
}

variable "domain_name" {
  description = "The domain name for the application (e.g., example.com.) - include trailing dot if using FQDN for zone lookup"
  type        = string
  // default     = "yourdomain.com."
}

// variable "acm_certificate_arn" {
//   description = "ARN of the ACM certificate for HTTPS listener on ALB"
//   type        = string
//   default     = ""
// }

// variable "ec2_key_pair_name" {
//   description = "Name of the EC2 Key Pair for SSH access (optional)"
//   type        = string
//   default     = ""
// }

variable "web_instance_type" {
  description = "EC2 instance type for the Web Tier"
  type        = string
  default     = "t3.micro"
}

variable "web_asg_min_size" {
  description = "Minimum number of instances in Web ASG"
  type        = number
  default     = 2
}

variable "web_asg_max_size" {
  description = "Maximum number of instances in Web ASG"
  type        = number
  default     = 4
}

variable "web_asg_desired_capacity" {
  description = "Desired number of instances in Web ASG"
  type        = number
  default     = 2
}

variable "app_instance_type" {
  description = "EC2 instance type for the App Tier"
  type        = string
  default     = "t3.small"
}

variable "app_server_port" {
  description = "Port the application server (Tomcat/Node.js) listens on"
  type        = number
  default     = 8080 // Example for Tomcat
}

variable "app_asg_min_size" {
  description = "Minimum number of instances in App ASG"
  type        = number
  default     = 2
}

variable "app_asg_max_size" {
  description = "Maximum number of instances in App ASG"
  type        = number
  default     = 4
}

variable "app_asg_desired_capacity" {
  description = "Desired number of instances in App ASG"
  type        = number
  default     = 2
}

variable "elasticache_node_type" {
  description = "Node type for ElastiCache Redis cluster"
  type        = string
  default     = "cache.t3.micro"
}

variable "db_instance_class" {
  description = "Instance class for RDS MySQL"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS MySQL in GB"
  type        = number
  default     = 20
}

variable "db_username" {
  description = "Username for the RDS MySQL database"
  type        = string
  default     = "adminuser"
}

variable "db_password" {
  description = "Password for the RDS MySQL database. If empty, a random one will be generated."
  type        = string
  default     = ""
  sensitive   = true
}

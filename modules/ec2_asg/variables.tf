// modules/ec2_asg/variables.tf

variable "project_name" {
  description = "Project name for tagging resources."
  type        = string
}

variable "tier_name" {
  description = "Name of the tier (e.g., 'web', 'app')."
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ASG."
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with instances."
  type        = list(string)
}

variable "user_data" {
  description = "User data script for EC2 instances."
  type        = string
  default     = null
}

variable "min_size" {
  description = "Minimum number of instances in the ASG."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in the ASG."
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG."
  type        = number
  default     = 1
}

variable "health_check_type" {
  description = "Health check type for ASG (EC2 or ELB)."
  type        = string
  default     = "ELB" // Use ELB health check if attached to a load balancer
}

variable "health_check_grace_period" {
  description = "Time (in seconds) after instance comes into service before checking health."
  type        = number
  default     = 300
}

variable "target_group_arns" {
  description = "List of Target Group ARNs to attach the ASG to."
  type        = list(string)
  default     = []
}

variable "iam_instance_profile_name" {
  description = "Name of the IAM instance profile to associate with EC2 instances."
  type        = string
  default     = null // No profile by default
}

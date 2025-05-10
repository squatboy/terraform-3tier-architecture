// modules/alb/variables.tf

variable "project_name" {
  description = "Project name for tagging resources."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where ALB will be created."
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB."
  type        = list(string)
}

variable "web_security_group_id" {
  description = "ID of the security group to associate with the ALB (typically web_sg)."
  type        = string
}

variable "health_check_path" {
  description = "Path for ALB health checks."
  type        = string
  default     = "/"
}

variable "target_port" {
  description = "Port on which targets receive traffic."
  type        = number
  default     = 80
}

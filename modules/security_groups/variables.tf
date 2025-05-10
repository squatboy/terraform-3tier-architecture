// modules/security_groups/variables.tf

variable "project_name" {
  description = "Project name for tagging resources."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where security groups will be created."
  type        = string
}

variable "db_port" {
  description = "Port number for the database (e.g., 3306 for MySQL, 5432 for PostgreSQL)."
  type        = number
  default     = 3306
}

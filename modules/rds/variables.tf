// modules/rds/variables.tf

variable "project_name" {
  description = "Project name for tagging resources."
  type        = string
}

variable "db_name" {
  description = "The name of the database to create when the DB instance is created."
  type        = string
}

variable "db_username" {
  description = "Username for the master DB user."
  type        = string
}

variable "db_password" {
  description = "Password for the master DB user."
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "The instance type of the RDS instance."
  type        = string
}

variable "db_allocated_storage" {
  description = "The allocated storage in gigabytes."
  type        = number
}

variable "db_engine" {
  description = "The database engine to use (e.g., mysql, postgres)."
  type        = string
}

variable "db_engine_version" {
  description = "The database engine version."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the DB subnet group."
  type        = string
}

variable "db_subnet_ids" {
  description = "A list of subnet IDs for the DB subnet group. Must be private subnets."
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Security group ID for the RDS instance."
  type        = string
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ."
  type        = bool
  default     = false // For cost reasons in dev/test; true for production
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted."
  type        = bool
  default     = true // False for production
}

variable "backup_retention_period" {
  description = "The days to retain backups for."
  type        = number
  default     = 0 // 0 to disable automated backups; set to 7-35 for production
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted."
  type        = bool
  default     = true
}

variable "availability_zones" {
  description = "List of AZs, used to determine the AZ for single AZ deployment if not multi_az."
  type        = list(string)
  default     = []
}

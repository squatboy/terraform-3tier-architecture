// modules/rds/outputs.tf

output "db_instance_address" {
  description = "The address of the RDS instance."
  value       = aws_db_instance.main.address
}

output "db_instance_endpoint" {
  description = "The connection endpoint for the RDS instance."
  value       = aws_db_instance.main.endpoint
}

output "db_instance_port" {
  description = "The port on which the DB instance is listening."
  value       = aws_db_instance.main.port
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance."
  value       = aws_db_instance.main.arn
}

output "db_subnet_group_name" {
  description = "The name of the DB subnet group."
  value       = aws_db_subnet_group.main.name
}

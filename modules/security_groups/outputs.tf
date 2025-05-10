// modules/security_groups/outputs.tf

output "web_sg_id" {
  description = "ID of the Web Tier Security Group."
  value       = aws_security_group.web_sg.id
}

output "app_sg_id" {
  description = "ID of the Application Tier Security Group."
  value       = aws_security_group.app_sg.id
}

output "db_sg_id" {
  description = "ID of the Database Tier Security Group."
  value       = aws_security_group.db_sg.id
}

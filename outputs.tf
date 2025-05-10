// outputs.tf
// Outputs from the root module.

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer for the web tier."
  value       = module.alb.alb_dns_name
}

output "rds_endpoint" {
  description = "Endpoint address of the RDS database instance."
  value       = module.rds.db_instance_endpoint
}

output "rds_port" {
  description = "Port of the RDS database instance."
  value       = module.rds.db_instance_port
}

output "web_tier_asg_name" {
  description = "Name of the Web Tier Auto Scaling Group."
  value       = module.web_tier.asg_name
}

output "app_tier_asg_name" {
  description = "Name of the App Tier Auto Scaling Group."
  value       = module.app_tier.asg_name
}

output "vpc_id" {
  description = "ID of the created VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.vpc.private_subnet_ids
}

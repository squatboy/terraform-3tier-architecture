// outputs.tf

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "app_route53_record_name" {
  description = "Route 53 record for the application"
  value       = aws_route53_record.app_dns.fqdn
}

output "web_asg_name" {
  description = "Name of the Web Tier Auto Scaling Group"
  value       = aws_autoscaling_group.web_asg.name
}

output "app_asg_name" {
  description = "Name of the App Tier Auto Scaling Group"
  value       = aws_autoscaling_group.app_asg.name
}

output "rds_instance_endpoint" {
  description = "Endpoint of the RDS MySQL instance"
  value       = aws_db_instance.mysql_db.endpoint
  sensitive   = true // Endpoint might be considered sensitive
}

output "rds_instance_port" {
  description = "Port of the RDS MySQL instance"
  value       = aws_db_instance.mysql_db.port
}

output "generated_db_password" {
  description = "Generated database password (if var.db_password was empty)"
  value       = var.db_password == "" ? random_password.db_password.result : "Password was provided manually"
  sensitive   = true
}

output "elasticache_redis_primary_endpoint" {
  description = "Primary endpoint for the ElastiCache Redis cluster"
  value       = aws_elasticache_replication_group.redis_cluster.primary_endpoint_address
  sensitive   = true // Endpoint might be considered sensitive
}

output "elasticache_redis_reader_endpoint" {
  description = "Reader endpoint for the ElastiCache Redis cluster (if applicable)"
  value       = aws_elasticache_replication_group.redis_cluster.reader_endpoint_address // May be empty if no read replicas or cluster mode disabled
  sensitive   = true                                                                    // Endpoint might be considered sensitive
}

output "waf_acl_arn" {
  description = "ARN of the WAFv2 Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}

output "vpc_id" {
  description = "ID of the main VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_app_subnet_ids" {
  description = "IDs of the private application subnets"
  value       = [for subnet in aws_subnet.private_app : subnet.id]
}

output "private_db_subnet_ids" {
  description = "IDs of the private database subnets"
  value       = [for subnet in aws_subnet.private_db : subnet.id]
}

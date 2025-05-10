// modules/alb/outputs.tf

output "alb_dns_name" {
  description = "DNS name of the ALB."
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB (for Route53 alias records)."
  value       = aws_lb.main.zone_id
}

output "alb_target_group_arn" {
  description = "ARN of the web tier target group."
  value       = aws_lb_target_group.web.arn
}

output "alb_arn" {
  description = "ARN of the ALB."
  value       = aws_lb.main.arn
}

output "alb_dns" {
  description = "Application Load Balancer DNS"
  value       = aws_lb.app.dns_name
}

output "cf_domain" {
  description = "CloudFront distribution domain"
  value       = aws_cloudfront_distribution.cf.domain_name
}

output "s3_bucket" {
  description = "Static assets S3 bucket"
  value       = aws_s3_bucket.static.bucket
}

output "redis_endpoint" {
  description = "Redis primary endpoint"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "rds_endpoint" {
  description = "RDS primary endpoint"
  value       = aws_db_instance.mysql.address
}

output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = data.aws_route53_zone.zone.zone_id
}

// modules/ec2_asg/outputs.tf

output "asg_name" {
  description = "The name of the Auto Scaling Group."
  value       = aws_autoscaling_group.main.name
}

output "asg_arn" {
  description = "The ARN of the Auto Scaling Group."
  value       = aws_autoscaling_group.main.arn
}

output "launch_template_id" {
  description = "The ID of the Launch Template."
  value       = aws_launch_template.main.id
}

output "launch_template_latest_version" {
  description = "The latest version of the Launch Template."
  value       = aws_launch_template.main.latest_version
}

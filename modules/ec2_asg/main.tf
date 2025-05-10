// modules/ec2_asg/main.tf

// Launch Template for EC2 instances
resource "aws_launch_template" "main" {
  name_prefix   = "${var.project_name}-${var.tier_name}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  user_data     = var.user_data != null ? base64encode(var.user_data) : null

  vpc_security_group_ids = var.security_group_ids

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  // Enable detailed monitoring if needed
  // monitoring {
  //   enabled = true
  // }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-${var.tier_name}-instance"
      Tier = var.tier_name
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.project_name}-${var.tier_name}-volume"
      Tier = var.tier_name
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

// Auto Scaling Group
resource "aws_autoscaling_group" "main" {
  name_prefix               = "${var.project_name}-${var.tier_name}-asg-"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  vpc_zone_identifier       = var.subnet_ids // ASG needs subnet IDs

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest" // Always use the latest version of the launch template
  }

  target_group_arns = var.target_group_arns // Attach to ALB Target Groups if provided

  // Ensure instances are replaced if the launch template changes
  // This helps with AMI updates or user_data changes
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.tier_name}-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = var.tier_name
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

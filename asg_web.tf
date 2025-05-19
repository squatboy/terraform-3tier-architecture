// asg_web.tf

//------------------------------------------------------------------------------
// Launch Template for Web Tier (Nginx/Apache)
//------------------------------------------------------------------------------
resource "aws_launch_template" "web_lt" {
  name_prefix   = "${local.project_name}-web-lt-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.web_instance_type
  // key_name = var.ec2_key_pair_name // Add if you need SSH access via key pair

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  // Basic user data to install Apache (httpd)
  // Replace with your actual web server setup and application deployment
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Web Tier - $(hostname -f)</h1>Deployed by Terraform" > /var/www/html/index.html
              # For Nginx:
              # amazon-linux-extras install nginx1 -y
              # systemctl start nginx
              # systemctl enable nginx
              # echo "<h1>Hello from Web Tier (Nginx) - $(hostname -f)</h1>Deployed by Terraform" > /usr/share/nginx/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${local.project_name}-web-instance"
      Tier = "Web"
    })
  }

  // iam_instance_profile { // Attach IAM role if instances need AWS API access
  //   name = aws_iam_instance_profile.ec2_profile.name // Define this IAM profile
  // }

  lifecycle {
    create_before_destroy = true // Useful for updates without downtime
  }
}

//------------------------------------------------------------------------------
// Auto Scaling Group for Web Tier
//------------------------------------------------------------------------------
resource "aws_autoscaling_group" "web_asg" {
  name_prefix               = "${local.project_name}-web-asg-"
  desired_capacity          = var.web_asg_desired_capacity
  max_size                  = var.web_asg_max_size
  min_size                  = var.web_asg_min_size
  health_check_type         = "ELB"                                         // Use ALB health checks
  health_check_grace_period = 300                                           // Seconds to allow instance to start before ELB health checks begin
  vpc_zone_identifier       = [for subnet in aws_subnet.public : subnet.id] // ASG deploys instances into public subnets

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest" // Always use the latest version of the launch template
  }

  target_group_arns = [aws_lb_target_group.web_tier_tg.arn] // Attach to ALB's web tier target group

  // Ensure new instances are launched before old ones are terminated during updates
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50 // Or your desired threshold
    }
  }

  // Propagate tags to instances
  tag {
    key                 = "Name"
    value               = "${local.project_name}-web-asg-instance"
    propagate_at_launch = true
  }
  tag {
    key                 = "Tier"
    value               = "Web"
    propagate_at_launch = true
  }
  tag {
    key                 = "Project"
    value               = local.project_name
    propagate_at_launch = true
  }
  tag {
    key                 = "Environment"
    value               = local.environment
    propagate_at_launch = true
  }
  tag {
    key                 = "ManagedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

// asg_app.tf

//------------------------------------------------------------------------------
// Launch Template for App Tier (Tomcat/Node.js)
//------------------------------------------------------------------------------
resource "aws_launch_template" "app_lt" {
  name_prefix   = "${local.project_name}-app-lt-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.app_instance_type
  // key_name = var.ec2_key_pair_name

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  // Placeholder user data for application server setup
  // Replace with your actual Tomcat/Node.js installation and app deployment
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              # Example for a simple Node.js app listening on var.app_server_port
              # amazon-linux-extras install nodejs18 -y # Example for Node.js 18
              # mkdir /opt/app
              # cat << NODEAPP > /opt/app/server.js
              # const http = require('http');
              # const server = http.createServer((req, res) => {
              #   res.writeHead(200, {'Content-Type': 'text/plain'});
              #   res.end('Hello from App Tier - $(hostname -f) on port ${var.app_server_port}\\n');
              # });
              # server.listen(${var.app_server_port}, '0.0.0.0', () => {
              #   console.log('App server running on port ${var.app_server_port}');
              # });
              # NODEAPP
              # node /opt/app/server.js > /var/log/app.log 2>&1 &

              # Placeholder:
              echo "App Tier instance $(hostname -f) started. Configure your app (Tomcat/Node.js) here." > /tmp/app_tier_ready.txt
              echo "App server should listen on port ${var.app_server_port}" >> /tmp/app_tier_ready.txt
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${local.project_name}-app-instance"
      Tier = "Application"
    })
  }

  // iam_instance_profile {
  //   name = aws_iam_instance_profile.ec2_profile.name // If app needs AWS service access
  // }

  lifecycle {
    create_before_destroy = true
  }
}

//------------------------------------------------------------------------------
// Auto Scaling Group for App Tier
//------------------------------------------------------------------------------
resource "aws_autoscaling_group" "app_asg" {
  name_prefix         = "${local.project_name}-app-asg-"
  desired_capacity    = var.app_asg_desired_capacity
  max_size            = var.app_asg_max_size
  min_size            = var.app_asg_min_size
  vpc_zone_identifier = [for subnet in aws_subnet.private_app : subnet.id] // App tier in private app subnets

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  // Health check type is "EC2" by default if not attached to an ELB/ALB target group.
  // If App Tier had its own ALB target group, set to "ELB" and add target_group_arns.
  health_check_type         = "EC2"
  health_check_grace_period = 300 // Give instances time to fully start

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${local.project_name}-app-asg-instance"
    propagate_at_launch = true
  }
  tag {
    key                 = "Tier"
    value               = "Application"
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

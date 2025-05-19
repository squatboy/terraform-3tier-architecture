// alb.tf

//------------------------------------------------------------------------------
// Application Load Balancer (ALB)
//------------------------------------------------------------------------------
resource "aws_lb" "main" {
  name               = "${local.project_name}-alb-${random_id.suffix.hex}" // Add suffix for potential recreation
  internal           = false                                               // Public facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id] // ALB in public subnets

  enable_deletion_protection = false // Set to true for production environments

  // access_logs { // Recommended for production
  //   bucket  = aws_s3_bucket.lb_logs.bucket
  //   prefix  = "alb-logs"
  //   enabled = true
  // }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-alb"
  })
}

//------------------------------------------------------------------------------
// Target Group for Web Tier
//------------------------------------------------------------------------------
resource "aws_lb_target_group" "web_tier_tg" {
  name        = "${local.project_name}-web-tg"
  port        = 80 // Port on which web servers listen
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance" // Could be 'ip' if using Fargate/ECS with awsvpc mode

  health_check {
    enabled             = true
    path                = "/"            // Default health check path for Nginx/Apache
    port                = "traffic-port" // Use the port of the target group
    protocol            = "HTTP"
    matcher             = "200-399" // Successful HTTP codes
    interval            = 30        // Seconds
    timeout             = 5         // Seconds
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-web-tg"
  })
}

//------------------------------------------------------------------------------
// ALB Listener for HTTP traffic
//------------------------------------------------------------------------------
// For simplicity, this handles HTTP directly.
// In production, you would typically redirect HTTP to HTTPS.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tier_tg.arn
  }
}

/*
//------------------------------------------------------------------------------
// ALB Listener for HTTPS traffic (Example - requires ACM certificate)
//------------------------------------------------------------------------------
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08" // Choose an appropriate security policy
  certificate_arn   = var.acm_certificate_arn     // Define this variable with your ACM cert ARN

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tier_tg.arn
  }
}

// Optional: HTTP to HTTPS redirect listener
resource "aws_lb_listener" "http_redirect_to_https" {
  count = var.acm_certificate_arn != "" ? 1 : 0 // Only create if HTTPS is configured

  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301" // Permanent redirect
    }
  }
}
*/

/*
// Example for an App Tier Target Group and Listener Rule (if ALB routes directly to App Tier)
//------------------------------------------------------------------------------
// Target Group for App Tier (if directly exposed via ALB)
//------------------------------------------------------------------------------
resource "aws_lb_target_group" "app_tier_tg" {
  // count = var.enable_app_tier_direct_routing ? 1 : 0 // Control with a variable
  name        = "${local.project_name}-app-tg"
  port        = var.app_server_port
  protocol    = "HTTP" // Or HTTPS if app servers handle SSL
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health" // Customize for your app's health endpoint
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    // ... other health check params
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-app-tg"
  })
}

//------------------------------------------------------------------------------
// Listener Rule for App Tier (e.g., for /api/* paths)
//------------------------------------------------------------------------------
resource "aws_lb_listener_rule" "app_api_rule" {
  // count = var.enable_app_tier_direct_routing ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn // Assuming HTTPS listener exists
  priority     = 10 // Lower numbers evaluated first

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tier_tg[0].arn
  }

  condition {
    path_pattern {
      values = ["/api/*"] // Route requests matching /api/* to the app tier
    }
  }
}
*/

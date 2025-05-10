// modules/alb/main.tf

// Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.web_security_group_id] // ALB uses the web SG for ingress
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false // Set to true for production

  tags = {
    Name = "${var.project_name}-alb"
  }
}

// Target Group for Web Tier
resource "aws_lb_target_group" "web" {
  name        = "${var.project_name}-web-tg"
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance" // Can be 'ip' or 'lambda' as well

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200-399" // Healthy if status code is 200-399
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-web-tg"
  }
}

// Listener for HTTP traffic on port 80
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

// Optional: Listener for HTTPS traffic on port 443
// resource "aws_lb_listener" "https" {
//   load_balancer_arn = aws_lb.main.arn
//   port              = "443"
//   protocol          = "HTTPS"
//   ssl_policy        = "ELBSecurityPolicy-2016-08" // Choose appropriate policy
//   certificate_arn   = "arn:aws:acm:REGION:ACCOUNT_ID:certificate/CERTIFICATE_ID" // Replace with your ACM cert ARN

//   default_action {
//     type             = "forward"
//     target_group_arn = aws_lb_target_group.web.arn
//   }
// }

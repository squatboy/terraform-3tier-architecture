// security_groups.tf

//------------------------------------------------------------------------------
// Security Group for Application Load Balancer (ALB)
//------------------------------------------------------------------------------
resource "aws_security_group" "alb_sg" {
  name        = "${local.project_name}-alb-sg"
  description = "Allow HTTP/HTTPS traffic to ALB from Internet (via WAF)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere (WAF is in front)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS from anywhere (WAF is in front)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic to Web Tier"
    from_port   = 0             // All ports
    to_port     = 0             // All ports
    protocol    = "-1"          // All protocols
    cidr_blocks = ["0.0.0.0/0"] // Or more restrictively, to web_sg on specific ports
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-alb-sg"
  })
}

//------------------------------------------------------------------------------
// Security Group for Web Tier (Nginx/Apache)
//------------------------------------------------------------------------------
resource "aws_security_group" "web_sg" {
  name        = "${local.project_name}-web-sg"
  description = "Allow traffic from ALB to Web Tier and outbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80 // Nginx/Apache listen port
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  // ingress { // Example for HTTPS from ALB if web tier terminates SSL (uncommon with ALB)
  //   description     = "HTTPS from ALB"
  //   from_port       = 443
  //   to_port         = 443
  //   protocol        = "tcp"
  //   security_groups = [aws_security_group.alb_sg.id]
  // }
  // Add SSH from bastion/management IP if needed:
  // ingress {
  //   description = "SSH from Bastion/Admin"
  //   from_port   = 22
  //   to_port     = 22
  //   protocol    = "tcp"
  //   cidr_blocks = [var.admin_bastion_ip_cidr] // Define this variable
  // }

  egress {
    description = "Allow all outbound traffic (to App Tier, Internet via NAT)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-web-sg"
  })
}

//------------------------------------------------------------------------------
// Security Group for App Tier (Tomcat/Node.js)
//------------------------------------------------------------------------------
resource "aws_security_group" "app_sg" {
  name        = "${local.project_name}-app-sg"
  description = "Allow traffic from Web Tier to App Tier and outbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App traffic from Web Tier"
    from_port       = var.app_server_port // e.g., 8080 for Tomcat, 3000 for Node.js
    to_port         = var.app_server_port
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id] // If Web tier proxies to App tier
    // If ALB directly targets App tier, this would be alb_sg.id for the app port
  }
  // Add SSH from bastion/management IP if needed

  egress {
    description = "Allow all outbound traffic (to DB, Cache, Internet via NAT)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-app-sg"
  })
}

//------------------------------------------------------------------------------
// Security Group for ElastiCache (Redis)
//------------------------------------------------------------------------------
resource "aws_security_group" "elasticache_sg" {
  name        = "${local.project_name}-elasticache-sg"
  description = "Allow traffic from App Tier to ElastiCache"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Redis from App Tier"
    from_port       = 6379 // Default Redis port
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  // Egress is typically not needed for ElastiCache unless it initiates connections,
  // but allowing all outbound is common for simplicity if not strictly controlled.
  egress {
    description = "Allow all outbound (not strictly necessary for ElastiCache itself)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-elasticache-sg"
  })
}

//------------------------------------------------------------------------------
// Security Group for RDS (MySQL)
//------------------------------------------------------------------------------
resource "aws_security_group" "rds_sg" {
  name        = "${local.project_name}-rds-sg"
  description = "Allow traffic from App Tier to RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from App Tier"
    from_port       = 3306 // Default MySQL port
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  // Egress is typically not needed for RDS unless it initiates connections.
  egress {
    description = "Allow all outbound (not strictly necessary for RDS itself)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-rds-sg"
  })
}

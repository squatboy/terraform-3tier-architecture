// modules/security_groups/main.tf

// Web Tier Security Group
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Allow HTTP/HTTPS inbound traffic and all outbound."
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Optional: Allow SSH from a specific IP for bastion/management
  // ingress {
  //   description = "SSH from bastion/management IP"
  //   from_port   = 22
  //   to_port     = 22
  //   protocol    = "tcp"
  //   cidr_blocks = ["YOUR_MANAGEMENT_IP/32"]
  // }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" // All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

// Application Tier Security Group
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-app-sg"
  description = "Allow traffic from Web SG and all outbound."
  vpc_id      = var.vpc_id

  ingress {
    description     = "Traffic from Web Tier SG"
    from_port       = 0     // Or specific app ports like 8080
    to_port         = 0     // Or specific app ports like 8080
    protocol        = "tcp" // Or specific protocol
    security_groups = [aws_security_group.web_sg.id]
  }

  // Optional: Allow SSH from a specific IP for bastion/management
  // ingress {
  //   description = "SSH from bastion/management IP"
  //   from_port   = 22
  //   to_port     = 22
  //   protocol    = "tcp"
  //   cidr_blocks = ["YOUR_MANAGEMENT_IP/32"]
  // }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

// Database Tier Security Group
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Allow traffic from App SG on DB port."
  vpc_id      = var.vpc_id

  ingress {
    description     = "DB traffic from Application Tier SG"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  // Typically, DBs don't need outbound internet access, but might need for specific cases
  // egress {
  //   from_port   = 0
  //   to_port     = 0
  //   protocol    = "-1"
  //   cidr_blocks = ["0.0.0.0/0"] // Restrict if possible
  // }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

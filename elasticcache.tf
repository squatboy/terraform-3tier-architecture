// rds.tf

//------------------------------------------------------------------------------
// RDS DB Subnet Group
//------------------------------------------------------------------------------
resource "aws_db_subnet_group" "main" {
  name       = "${local.project_name}-db-subnet-group"
  subnet_ids = [for subnet in aws_subnet.private_db : subnet.id] // RDS in private DB/Cache subnets

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-db-subnet-group"
  })
}

//------------------------------------------------------------------------------
// Random Password for DB (if not provided)
//------------------------------------------------------------------------------
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "_%@." // Ensure characters are valid for MySQL passwords
}

//------------------------------------------------------------------------------
// RDS DB Instance (MySQL)
//------------------------------------------------------------------------------
resource "aws_db_instance" "mysql_db" {
  identifier_prefix      = "${local.project_name}-mysql-" // AWS will append a unique suffix
  allocated_storage      = var.db_allocated_storage
  storage_type           = "gp3" // General Purpose SSD v3 (consider gp3 over gp2)
  engine                 = "mysql"
  engine_version         = "8.0" // Specify your desired MySQL version (e.g., "8.0.35")
  instance_class         = var.db_instance_class
  db_name                = "${replace(local.project_name, "-", "")}db" // Initial database name (no hyphens)
  username               = var.db_username
  password               = var.db_password == "" ? random_password.db_password.result : var.db_password
  parameter_group_name   = "default.mysql8.0" // Or specify a custom parameter group
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  multi_az            = true  // Creates a standby instance in a different AZ (as per diagram)
  publicly_accessible = false // Keep DB private

  skip_final_snapshot     = true // Set to false for production, and specify final_snapshot_identifier
  backup_retention_period = 7    // Days, adjust as needed for production
  // storage_encrypted      = true  // Recommended for production
  // kms_key_id             = aws_kms_key.rds.arn // If using customer-managed KMS key

  // performance_insights_enabled = true // Optional, for performance monitoring

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-mysql-db"
  })

  depends_on = [aws_db_subnet_group.main]
}

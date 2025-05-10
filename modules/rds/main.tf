// modules/rds/main.tf

// DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

// RDS Instance
resource "aws_db_instance" "main" {
  identifier             = "${lower(var.project_name)}-db-instance" // Must be lowercase
  allocated_storage      = var.db_allocated_storage
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = var.db_engine == "mysql" ? "default.mysql${split(".", var.db_engine_version)[0]}.${split(".", var.db_engine_version)[1]}" : (var.db_engine == "postgres" ? "default.postgres${split(".", var.db_engine_version)[0]}" : null) // Example for mysql/postgres
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_security_group_id]

  multi_az = var.multi_az
  // If not multi_az, specify a single AZ. Take the first from the provided list.
  availability_zone = var.multi_az == false && length(var.availability_zones) > 0 ? var.availability_zones[0] : null


  skip_final_snapshot     = var.skip_final_snapshot
  backup_retention_period = var.backup_retention_period
  storage_encrypted       = var.storage_encrypted

  # Deletion protection should be enabled for production environments
  # deletion_protection    = true 

  tags = {
    Name = "${var.project_name}-db-instance"
  }

  # Prevent updates if password is not specified in a plan (prevents accidental reset to null)
  lifecycle {
    ignore_changes = [password]
  }
}

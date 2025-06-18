resource "random_password" "db" {
  length  = 16
  special = true
}

resource "aws_db_subnet_group" "db" {
  name       = "${var.project}-db-subnet"
  subnet_ids = values(aws_subnet.data)[*].id
  tags = {
    Project = var.project
  }
}

resource "aws_db_instance" "mysql" {
  identifier             = "${var.project}-rds"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  storage_type           = "gp2"
  multi_az               = true
  username               = "admin"
  password               = random_password.db.result
  skip_final_snapshot    = true
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.db.name
  tags = {
    Project = var.project
  }
}

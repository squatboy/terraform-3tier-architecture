resource "aws_elasticache_subnet_group" "cache" {
  name       = "${var.project}-cache-subnet"
  subnet_ids = values(aws_subnet.app)[*].id
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.project}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  subnet_group_name    = aws_elasticache_subnet_group.cache.name
  security_group_ids   = [aws_security_group.cache.id]
  parameter_group_name = "default.redis6.x"
  tags = {
    Project = var.project
  }
}

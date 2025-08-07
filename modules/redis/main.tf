resource "aws_elasticache_subnet_group" "redis" {
  name        = "${var.project_name}-redis-subnet-group"
  description = "Subnet group for n8n Redis ElastiCache"
  subnet_ids  = var.subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-redis-subnet-group"
  })
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.project_name}-redis"
  description                = "n8n Redis ${var.project_name}"
  node_type                  = var.redis_saas_node_type
  num_node_groups            = 1
  replicas_per_node_group    = 0
  engine                     = "redis"
  engine_version             = "7.0"
  automatic_failover_enabled = false
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [aws_security_group.redis.id]
  port                       = 6379
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-redis"
  })
}

resource "aws_security_group" "redis" {
  name        = "${var.project_name}-redis-sg"
  description = "Security group for n8n Redis ElastiCache"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-redis-sg"
  })
}


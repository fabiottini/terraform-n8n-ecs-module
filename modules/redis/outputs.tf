output "redis_endpoint" {
  description = "ElastiCache Redis endpoint hostname."
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
  depends_on  = [aws_elasticache_replication_group.redis]
} 
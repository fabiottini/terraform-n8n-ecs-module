output "ecs_cluster_id" {
  description = "ECS cluster ID."
  value       = aws_ecs_cluster.this.id
}

output "n8n_master_service_name" {
  description = "n8n master ECS service name."
  value       = aws_ecs_service.n8n_master.name
}

output "n8n_worker_service_name" {
  description = "n8n worker ECS service name."
  value       = aws_ecs_service.n8n_worker.name
}

# output "redis_service_name" {
#   description = "Redis ECS service name (if used)."
#   value       = aws_ecs_service.redis.name
# }

# output "redis_endpoint" {
#   description = "Redis endpoint (if ECS container is used)."
#   value       = aws_service_discovery_service.redis.endpoint
# }

output "n8n_public_url" {
  description = "n8n public URL."
  value       = aws_lb.this.dns_name
}


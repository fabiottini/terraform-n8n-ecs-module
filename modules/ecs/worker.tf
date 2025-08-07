# ===============================================================================
# N8N WORKER SERVICE CONFIGURATION
# ===============================================================================
#
# Worker services execute workflows from the Redis queue in a distributed fashion.
# This enables horizontal scaling based on workload demands and provides fault
# tolerance for production workflow execution.
#
# SCALING CHARACTERISTICS:
# - Auto-scaling based on CPU utilization metrics
# - Configurable min/max capacity for cost optimization
# - Stateless design enables rapid scaling operations
# - Multiple workers process queue concurrently
#
# EXECUTION RESPONSIBILITIES:
# - Process scheduled workflow executions
# - Handle webhook-triggered workflows  
# - Execute workflows offloaded from master service
# - Maintain execution state in shared database
# - Report metrics and logging to CloudWatch
#
# RESOURCE OPTIMIZATION:
# - CPU/Memory allocation based on workflow complexity
# - Network-optimized for database and Redis communication
# - Ephemeral storage for temporary workflow data
# ===============================================================================
resource "aws_cloudwatch_log_group" "n8n_worker" {
  name              = "/ecs/${var.project_name}/n8n-worker"
  retention_in_days = var.log_retention_days
  tags              = merge(var.common_tags, { Name = "${var.project_name}-n8n-worker" })
}

resource "aws_ecs_task_definition" "n8n_worker" {
  family                   = "n8n-worker"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.worker_fargate_cpu
  memory                   = var.worker_fargate_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name    = "n8n-worker"
      image   = var.n8n_image
      command = ["worker"]
      portMappings = [
        { containerPort = 5678, protocol = "tcp" },
        { containerPort = 5679, protocol = "tcp" }
      ]
      environment = concat(
        local.environment,
        [{ name = "N8N_WORKER_MODE", value = "worker" },
        { name = "N8N_WORKER", value = "true" }]
      )
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project_name}/n8n-worker"
          awslogs-region        = "${var.aws_region}"
          awslogs-stream-prefix = "ecs"
        }
      }
      healthCheck = {
        command     = ["CMD", "nc", "-z", "localhost", "5678"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
    }
  ])
  depends_on = [aws_cloudwatch_log_group.n8n_worker]
  tags       = merge(var.common_tags, { Name = "n8n-worker" })

  lifecycle {
    ignore_changes = [container_definitions]
  }
}

resource "aws_ecs_service" "n8n_worker" {
  name                   = "n8n-worker"
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.n8n_worker.arn
  desired_count          = var.desired_count_worker
  launch_type            = "FARGATE"
  enable_execute_command = true
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_n8n_tasks.id]
    assign_public_ip = false
  }
  depends_on = [aws_ecs_task_definition.n8n_worker]
  tags       = merge(var.common_tags, { Name = "n8n-worker" })
}

# ===================================================================
# AUTOSCALING
# ===================================================================

resource "aws_appautoscaling_target" "n8n_worker" {
  max_capacity       = var.autoscaling_worker_max_capacity # Modifica secondo necessità
  min_capacity       = var.autoscaling_worker_min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.n8n_worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "n8n_worker_cpu" {
  name               = "${var.project_name}-n8n-worker-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.n8n_worker.resource_id
  scalable_dimension = aws_appautoscaling_target.n8n_worker.scalable_dimension
  service_namespace  = aws_appautoscaling_target.n8n_worker.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 60.0 # percentuale di CPU
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }

}

resource "aws_appautoscaling_policy" "n8n_worker_memory" {
  name               = "${var.project_name}-n8n-worker-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.n8n_worker.resource_id
  scalable_dimension = aws_appautoscaling_target.n8n_worker.scalable_dimension
  service_namespace  = aws_appautoscaling_target.n8n_worker.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 75.0 # % of memory
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# resource "aws_appautoscaling_policy" "n8n_worker_connections" {
#   name               = "${var.project_name}-n8n-worker-connections-scaling"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.n8n_worker.resource_id
#   scalable_dimension = aws_appautoscaling_target.n8n_worker.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.n8n_worker.service_namespace

#   target_tracking_scaling_policy_configuration {
#     customized_metric_specification {
#       metric_name = "ActiveConnections"
#       namespace   = "Custom/N8N"
#       statistic   = "Average"
#       unit        = "Count"
#     }
#     target_value       = 100.0 # number of connections target per task
#     scale_in_cooldown  = 60
#     scale_out_cooldown = 60
#   }
# }
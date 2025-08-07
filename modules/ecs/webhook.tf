
# ===============================================================================
# N8N WEBHOOK SERVICE CONFIGURATION  
# ===============================================================================
#
# Dedicated webhook processing service that handles external HTTP requests
# and triggers workflow executions. Separation from the master service prevents
# webhook traffic from impacting the web UI performance.
#
# SERVICE ARCHITECTURE:
# - Load-balanced deployment across multiple availability zones
# - Dedicated endpoint separate from main n8n interface
# - Optimized for high-throughput webhook processing
# - Independent scaling from master and worker services
#
# SECURITY AND PERFORMANCE:
# - SSL termination at Application Load Balancer
# - Private subnet deployment with internet access via NAT
# - Configurable instance count based on webhook volume
# - Rate limiting and DDoS protection via ALB
# - Integration with CloudWatch for request monitoring
#
# WEBHOOK RESPONSIBILITIES:
# - Process incoming HTTP POST requests from external systems
# - Validate webhook signatures and authentication
# - Queue workflow executions for worker processing
# - Return appropriate HTTP responses to external systems
# - Log webhook activity for audit and debugging
# ===============================================================================
resource "aws_cloudwatch_log_group" "n8n_webhook" {
  name              = "/ecs/${var.project_name}/n8n-webhook"
  retention_in_days = var.log_retention_days
  tags = merge(var.common_tags, {

    Name       = "${var.project_name}-n8n-webhook"
  })
}

resource "aws_ecs_task_definition" "n8n_webhook" {
  family                   = "n8n-webhook"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.webhook_fargate_cpu
  memory                   = var.webhook_fargate_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name  = "n8n-webhook"
      image = var.n8n_image
      portMappings = [
        { containerPort = 5678, protocol = "tcp" }
      ]
      environment = concat(
        local.environment,
        [
          { name = "N8N_WORKER_MODE", value = "webhook" },
          { name = "N8N_DISABLE_UI", value = "true" } # not needed for webhook mode
        ]
      )
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project_name}/n8n-webhook"
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
  depends_on = [aws_cloudwatch_log_group.n8n_webhook]
  tags = merge(var.common_tags, {

    Name       = "n8n-webhook"
  })
  lifecycle {
    ignore_changes = [container_definitions]
  }
}

resource "aws_ecs_service" "n8n_webhook" {
  name                   = "n8n-webhook"
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.n8n_webhook.arn
  desired_count          = var.desired_count_webhook
  launch_type            = "FARGATE"
  enable_execute_command = true
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_n8n_tasks.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.n8n_webhook.arn
    container_name   = "n8n-webhook"
    container_port   = 5678
  }
  depends_on = [aws_ecs_task_definition.n8n_webhook]
  tags = merge(var.common_tags, {

    Name       = "${var.project_name}-n8n-webhook"
  })
}


# ===================================================================
# AUTOSCALING
# ===================================================================

resource "aws_appautoscaling_target" "n8n_webhook" {
  max_capacity       = var.autoscaling_webhook_max_capacity
  min_capacity       = var.autoscaling_webhook_min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.n8n_webhook.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = merge(var.common_tags, {

    Name       = "${var.project_name}-n8n-webhook"
  })
}

resource "aws_appautoscaling_policy" "n8n_webhook_cpu" {
  name               = "${var.project_name}-n8n-webhook-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.n8n_webhook.resource_id
  scalable_dimension = aws_appautoscaling_target.n8n_webhook.scalable_dimension
  service_namespace  = aws_appautoscaling_target.n8n_webhook.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 60.0 # % of CPU
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }

}

resource "aws_appautoscaling_policy" "n8n_webhook_memory" {
  name               = "${var.project_name}-n8n-webhook-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.n8n_webhook.resource_id
  scalable_dimension = aws_appautoscaling_target.n8n_webhook.scalable_dimension
  service_namespace  = aws_appautoscaling_target.n8n_webhook.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 75.0 # % of memory
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }

}

resource "aws_appautoscaling_policy" "n8n_webhook_connections" {
  name               = "${var.project_name}-n8n-webhook-connections-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.n8n_webhook.resource_id
  scalable_dimension = aws_appautoscaling_target.n8n_webhook.scalable_dimension
  service_namespace  = aws_appautoscaling_target.n8n_webhook.service_namespace

  target_tracking_scaling_policy_configuration {
    customized_metric_specification {
      metric_name = "ActiveConnections"
      namespace   = "Custom/N8N"
      statistic   = "Average"
      unit        = "Count"
    }
    target_value       = 100.0 # number of connections target per task
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

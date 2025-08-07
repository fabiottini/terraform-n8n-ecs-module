
# ===============================================================================
# N8N MASTER SERVICE CONFIGURATION
# ===============================================================================
# 
# The master service provides the primary n8n web interface and API endpoints.
# It handles workflow design, testing, user management, and system configuration.
# 
# DEPLOYMENT CHARACTERISTICS:
# - Single instance deployment (no horizontal scaling)
# - Handles web UI and REST API requests
# - Manages workflow orchestration and scheduling
# - Processes manual workflow executions
# - Serves as coordination point for worker services
#
# RESOURCE CONFIGURATION:
# - CPU/Memory: Configurable based on expected concurrent users
# - Network: Private subnet with ALB frontend
# - Storage: Stateless (all data in PostgreSQL database)
# - Logging: Centralized CloudWatch integration
# ===============================================================================
resource "aws_cloudwatch_log_group" "n8n_master" {
  name              = "/ecs/${var.project_name}/n8n-master"
  retention_in_days = var.log_retention_days
  tags              = merge(var.common_tags, { Name = "${var.project_name}-n8n-master" })
}

resource "aws_ecs_task_definition" "n8n_master" {
  family                   = "n8n-master"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.master_fargate_cpu
  memory                   = var.master_fargate_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name  = "n8n-master"
      image = var.n8n_image
      portMappings = [
        { containerPort = 5678, protocol = "tcp" },
        { containerPort = 5679, protocol = "tcp" }
      ]
      environment = concat(
        local.environment,
        [
          { name = "N8N_WORKER_MODE", value = "master" }
        ]
      )
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project_name}/n8n-master"
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
  depends_on = [aws_cloudwatch_log_group.n8n_master]
  tags       = merge(var.common_tags, { Name = "n8n-master" })
  lifecycle {
    ignore_changes = [container_definitions]
  }
}

resource "aws_ecs_service" "n8n_master" {
  name                   = "n8n-master"
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.n8n_master.arn
  desired_count          = var.desired_count_master
  launch_type            = "FARGATE"
  enable_execute_command = true
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_n8n_tasks.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.n8n_master.arn
    container_name   = "n8n-master"
    container_port   = 5678
  }
  depends_on = [aws_ecs_task_definition.n8n_master]
  tags       = merge(var.common_tags, { Name = "${var.project_name}-n8n-master" })
}

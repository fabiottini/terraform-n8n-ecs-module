# ===================================================================
# REDIS
# ===================================================================
resource "aws_cloudwatch_log_group" "redis" {
  count             = var.use_elasticache_saas ? 0 : 1
  name              = "/ecs/${var.project_name}/redis"
  retention_in_days = var.log_retention_days
  tags              = var.common_tags
}

resource "aws_ecs_task_definition" "redis" {
  count                    = var.use_elasticache_saas ? 0 : 1
  family                   = "redis"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name         = "redis"
      image        = var.redis_image
      portMappings = [{ containerPort = 6379, protocol = "tcp" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project_name}/redis"
          awslogs-region        = "${var.aws_region}"
          awslogs-stream-prefix = "ecs"
        }
      }
      healthCheck = {
        command     = ["CMD", "redis-cli", "ping"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
    }
  ])
  depends_on = [aws_cloudwatch_log_group.redis]
  tags       = merge(var.common_tags, { Name = "${var.project_name}-redis" })

  lifecycle {
    ignore_changes = [container_definitions]
  }
}

resource "aws_lb" "redis" {
  count              = var.use_elasticache_saas ? 0 : 1
  name               = "${var.project_name}-redis-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_subnet_ids
  tags               = merge(var.common_tags, { Name = "${var.project_name}-redis-nlb" })
}

resource "aws_lb_target_group" "redis" {
  count       = var.use_elasticache_saas ? 0 : 1
  name        = "${var.project_name}-redis-tg"
  port        = 6379
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    protocol = "TCP"
    port     = "6379"
  }
  tags = merge(var.common_tags, { Name = "${var.project_name}-redis-tg" })
}

resource "aws_lb_listener" "redis" {
  count             = var.use_elasticache_saas ? 0 : 1
  load_balancer_arn = aws_lb.redis[0].arn
  port              = 6379
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.redis[0].arn
  }
}

resource "aws_ecs_service" "redis" {
  count                  = var.use_elasticache_saas ? 0 : 1
  name                   = "redis"
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.redis[0].arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_redis_tasks.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.redis[0].arn
    container_name   = "redis"
    container_port   = 6379
  }
  depends_on = [aws_ecs_task_definition.redis]
  tags       = var.common_tags
}

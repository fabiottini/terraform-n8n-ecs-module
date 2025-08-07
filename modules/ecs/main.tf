# ===============================================================================
# N8N ECS MODULE - CORE CONFIGURATION
# ===============================================================================
# 
# This module manages the complete n8n workflow automation platform deployment
# on AWS ECS Fargate with queue mode architecture for production scalability.
#
# ARCHITECTURE OVERVIEW:
# - Master Service: Web UI, API endpoints, workflow management (single instance)
# - Worker Services: Distributed workflow execution from Redis queue (auto-scaling)
# - Webhook Services: External webhook processing (load balanced)
# - Redis Queue: Message broker for distributed task processing
# - Load Balancers: Separate ALBs for UI and webhook endpoints with SSL termination
#
# SECURITY FEATURES:
# - Private subnet deployment for all containers
# - IAM roles with least privilege principles  
# - SSL/TLS termination at load balancer level
# - Database connection encryption
# - Secrets management via environment variables
# ===============================================================================

# ===============================================================================
# LOCAL VALUES AND COMPUTED VARIABLES
# ===============================================================================
# Configuration values computed from input variables and resource references.
# These locals centralize environment variable configuration and connection
# strings for consistent usage across all n8n service deployments.
# ===============================================================================
locals {
  db_endpoint_host = split(":", var.db_endpoint)[0]
  db_endpoint_port = var.db_endpoint_port #(split(":", var.db_endpoint)[1] == null) ? var.db_endpoint_port : split(":", var.db_endpoint)[1]
  queue_redis_host = var.redis_endpoint != null ? var.redis_endpoint : aws_lb.redis[0].dns_name
  environment = [
    { name = "N8N_BASIC_AUTH_ACTIVE", value = var.n8n_basic_auth_user != null ? "true" : "false" },
    { name = "N8N_BASIC_AUTH_USER", value = var.n8n_basic_auth_user },
    { name = "N8N_BASIC_AUTH_PASSWORD", value = var.n8n_basic_auth_password },
    { name = "DB_TYPE", value = "postgresdb" },
    { name = "DB_POSTGRESDB_HOST", value = local.db_endpoint_host },
    { name = "DB_POSTGRESDB_PORT", value = tostring(local.db_endpoint_port) },
    { name = "DB_POSTGRESDB_DATABASE", value = var.db_name },
    { name = "DB_POSTGRESDB_USER", value = var.db_username },
    { name = "DB_POSTGRESDB_PASSWORD", value = var.db_password },
    { name = "DB_POSTGRESDB_SCHEMA", value = "public" },
    { name = "DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED", value = "false" },
    { name = "DB_POSTGRESDB_SSL", value = "true" },
    { name = "QUEUE_MODE", value = "redis" },
    { name = "QUEUE_BULL_REDIS_HOST", value = local.queue_redis_host },
    { name = "QUEUE_BULL_REDIS_PORT", value = "6379" },
    { name = "N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS", value = "true" },
    { name = "N8N_SECURE_COOKIE", value = "false" },
    { name = "N8N_LOG_LEVEL", value = var.n8n_log_level },
    { name = "EXECUTIONS_MODE", value = "queue" },
    { name = "WEBHOOK_URL", value = "https://${var.domain_webhook}" },
    { name = "N8N_EDITOR_BASE_URL", value = "https://${var.domain_master}" },
    { name = "N8N_HOST", value = "${var.domain_master}" },
    { name = "N8N_PORT", value = "5678" },
    { name = "N8N_LISTEN_ADDRESS", value = "0.0.0.0" },
    { name = "N8N_ENCRYPTION_KEY", value = var.n8n_encryption_key },
    { name = "N8N_METRICS", value = "true" },
    { name = "OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS", value = "true" },
    { name = "N8N_CONCURRENCY_PRODUCTION_LIMIT", value = "600" },
    # { name = "N8N_RUNNERS_ENABLED", value = "true" },
    # { name = "N8N_RUNNERS_MODE", value = "external" },
    # { name = "N8N_RUNNERS_BROKER_LISTEN_ADDRESS", value = "0.0.0.0" },
    # { name = "N8N_RUNNERS_AUTH_TOKEN", value = var.n8n_runners_auth_token },
    # { name = "N8N_RUNNERS_TASK_BROKER_URI", value = "http://${aws_lb.n8n_master.dns_name}:5679" },
    { name = "N8N_DIAGNOSTICS_ENABLED", value = "false" },
    { name = "EXPRESS_TRUST_PROXY", value = "true" },
    { name = "N8N_PROXY_HOPS", value = "1" },
    # { name = "N8N_ENDPOINT_WEBHOOK", value = "webhook" }, 
    # { name = "N8N_ENDPOINT_REST", value = "https://${var.domain_master}" },
    # { name = "N8N_ENDPOINT_WEBHOOK_TEST", value = "webhook_test" },
  ]
}

# ===================================================================
# IAM ROLES & POLICIES
# ===================================================================
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
  tags = merge(var.common_tags, { Name = "${var.project_name}-ecs-task-execution-role" })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_ssm" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "ecs_task_execution_cloudwatch" {
  name = "${var.project_name}-ecs-task-execution-cloudwatch-policy"
  role = aws_iam_role.ecs_task_execution.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["cloudwatch:PutMetricData"]
      Resource = "*"
    }]
  })
}

# ===================================================================
# SECURITY GROUPS
# ===================================================================
resource "aws_security_group" "ecs_redis_tasks" {
  name        = "${var.project_name}-ecs-redis-tasks"
  description = "Security group for ECS redis tasks"
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
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.common_tags, { Name = "${var.project_name}-ecs-redis-tasks" })
}

resource "aws_security_group" "ecs_n8n_tasks" {
  name        = "${var.project_name}-ecs-n8n-tasks"
  description = "Security group for ECS n8n tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5678
    to_port     = 5679
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.common_tags, { Name = "${var.project_name}-ecs-n8n-tasks" })
}

# ===================================================================
# ECS CLUSTER
# ===================================================================
resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"
  tags = var.common_tags

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

}



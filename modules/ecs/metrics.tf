resource "aws_cloudwatch_metric_alarm" "ecs_running_task_count" {
  alarm_name          = "${var.project_name}-ecs-running-task-count"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "The number of running ECS tasks is less than 1."
  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.n8n_worker.name
  }
  treat_missing_data = "notBreaching"
  tags               = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_pending_task_count" {
  alarm_name          = "${var.project_name}-ecs-pending-task-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "PendingTaskCount"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "There are ECS tasks in pending state."
  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.n8n_worker.name
  }
  treat_missing_data = "notBreaching"
  tags               = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_utilization" {
  alarm_name          = "${var.project_name}-ecs-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS CPU usage above 80%."
  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.n8n_worker.name
  }
  treat_missing_data = "notBreaching"
  tags               = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_utilization" {
  alarm_name          = "${var.project_name}-ecs-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS memory usage above 80%."
  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.n8n_worker.name
  }
  treat_missing_data = "notBreaching"
  tags               = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_task_stopped_count" {
  alarm_name          = "${var.project_name}-ecs-task-stopped-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TaskStoppedCount"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "There are ECS tasks stopped (Stopped) in the 5-minute period."
  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.n8n_worker.name
  }
  treat_missing_data = "notBreaching"
  tags               = var.common_tags
}

# ===================================================================
# LOCALS FOR DASHBOARD METRICS
# ===================================================================
locals {
  # Base metrics for n8n services
  base_task_metrics = [
    ["ECS/ContainerInsights", "TaskSetCount", "ServiceName", aws_ecs_service.n8n_worker.name, "ClusterName", aws_ecs_cluster.this.name, { "region" : var.aws_region }],
    [".", "DesiredTaskCount", ".", ".", ".", ".", { "region" : var.aws_region }],
    [".", "RunningTaskCount", ".", ".", ".", ".", { "region" : var.aws_region }],
    [".", "PendingTaskCount", ".", ".", ".", ".", { "region" : var.aws_region }],
    [".", "TaskSetCount", ".", aws_ecs_service.n8n_webhook.name, ".", ".", { "region" : var.aws_region }],
    [".", "DesiredTaskCount", ".", ".", ".", ".", { "region" : var.aws_region }],
    [".", "RunningTaskCount", ".", ".", ".", ".", { "region" : var.aws_region }],
    [".", "PendingTaskCount", ".", ".", ".", ".", { "region" : var.aws_region }],
    [".", "TaskSetCount", ".", aws_ecs_service.n8n_master.name, ".", ".", { "region" : var.aws_region }],
    [".", "DesiredTaskCount", ".", ".", ".", ".", { "region" : var.aws_region }],
    [".", "RunningTaskCount", ".", ".", ".", ".", { "region" : var.aws_region }],
    [".", "PendingTaskCount", ".", ".", ".", ".", { "region" : var.aws_region }]
  ]

  # Redis metrics (only if Redis resources exist)
  redis_task_metrics = !var.use_elasticache_saas ? [
    [".", "TaskSetCount", ".", aws_ecs_service.redis[0].name, ".", ".", { "region" : var.aws_region }],
    [".", "DesiredTaskCount", ".", ".", ".", ".", { "region" : var.aws_region }],
    [".", "RunningTaskCount", ".", ".", ".", ".", { "region" : var.aws_region }],
    [".", "PendingTaskCount", ".", ".", ".", ".", { "region" : var.aws_region }]
  ] : []

  # Combined task metrics
  all_task_metrics = concat(local.base_task_metrics, local.redis_task_metrics)

  # Base utilization metrics for n8n services
  base_utilization_metrics = [
    ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.this.name, "ServiceName", aws_ecs_service.n8n_worker.name],
    [".", "MemoryUtilization", ".", ".", ".", aws_ecs_service.n8n_worker.name],
    [".", "CPUUtilization", ".", ".", ".", aws_ecs_service.n8n_webhook.name],
    [".", "MemoryUtilization", ".", ".", ".", aws_ecs_service.n8n_webhook.name],
    [".", "CPUUtilization", ".", ".", ".", aws_ecs_service.n8n_master.name],
    [".", "MemoryUtilization", ".", ".", ".", aws_ecs_service.n8n_master.name]
  ]

  # Redis utilization metrics (only if Redis resources exist)
  redis_utilization_metrics = var.redis_endpoint == null ? [
    [".", "CPUUtilization", ".", ".", ".", aws_ecs_service.redis[0].name],
    [".", "MemoryUtilization", ".", ".", ".", aws_ecs_service.redis[0].name]
  ] : []

  # Combined utilization metrics
  all_utilization_metrics = concat(local.base_utilization_metrics, local.redis_utilization_metrics)
}

resource "aws_cloudwatch_dashboard" "ecs_dashboard" {
  dashboard_name = "${var.project_name}-ecs"
  dashboard_body = jsonencode({
    widgets = [
      {
        height = 6
        width  = 12
        y      = 0
        x      = 0
        type   = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.this.arn_suffix],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          period = 60
          region = var.aws_region
          stat   = "Sum"
          title  = "ALB Request Count & Errors (4XX/5XX)"
        }
      },
      {
        height = 12
        width  = 12
        y      = 0
        x      = 12
        type   = "metric"
        properties = {
          metrics = local.all_task_metrics
          period  = 60
          region  = var.aws_region
          stat    = "Maximum"
          title   = "ECS Task Count"
        }
      },
      {
        height = 6
        width  = 12
        y      = 6
        x      = 0
        type   = "metric"
        properties = {
          metrics = local.all_utilization_metrics
          period  = 60
          region  = var.aws_region
          stat    = "Average"
          title   = "ECS Utilization"
        }
      }
    ]
  })
} 
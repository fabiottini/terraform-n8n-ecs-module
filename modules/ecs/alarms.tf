# ===================================================================
# CLOUDWATCH ALARMS FOR ECS SERVICES
# ===================================================================

locals {
  alarm_actions = var.alarm_sns_topic_arn != null ? var.alarm_sns_topic_arn : []
  ok_actions    = var.alarm_sns_topic_arn != null ? var.alarm_sns_topic_arn : []
}

# ===================================================================
# ALARMS FOR N8N MASTER SERVICE
# ===================================================================

resource "aws_cloudwatch_metric_alarm" "master_cpu_utilization" {
  count               = var.enable_detailed_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-master-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "N8N Master CPU utilization is above 80%"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.n8n_master.name
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-master-cpu-alarm"
    Service = "n8n-master"
  })

}

resource "aws_cloudwatch_metric_alarm" "master_memory_utilization" {
  count               = var.enable_detailed_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-master-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "N8N Master memory utilization is above 85%"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.n8n_master.name
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-master-memory-alarm"
    Service = "n8n-master"
  })
}

resource "aws_cloudwatch_metric_alarm" "master_running_task_count" {
  count               = var.enable_detailed_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-master-running-tasks"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.desired_count_master
  alarm_description   = "N8N Master running tasks below desired count"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.ok_actions
  treat_missing_data  = "breaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.n8n_master.name
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-master-tasks-alarm"
    Service = "n8n-master"
  })
}

# ===================================================================
# ALARMS FOR N8N WORKER SERVICE
# ===================================================================

resource "aws_cloudwatch_metric_alarm" "worker_cpu_utilization" {
  count               = var.enable_detailed_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-worker-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "N8N Worker CPU utilization is above 80%"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.n8n_worker.name
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-worker-cpu-alarm"
    Service = "n8n-worker"
  })
}

resource "aws_cloudwatch_metric_alarm" "worker_memory_utilization" {
  count               = var.enable_detailed_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-worker-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "N8N Worker memory utilization is above 85%"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.n8n_worker.name
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-worker-memory-alarm"
    Service = "n8n-worker"
  })
}

resource "aws_cloudwatch_metric_alarm" "worker_running_task_count" {
  count               = var.enable_detailed_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-worker-running-tasks"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.desired_count_worker
  alarm_description   = "N8N Worker running tasks below desired count"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.n8n_worker.name
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-worker-tasks-alarm"
    Service = "n8n-worker"
  })
}

# ===================================================================
# ALARMS FOR N8N WEBHOOK SERVICE
# ===================================================================

resource "aws_cloudwatch_metric_alarm" "webhook_cpu_utilization" {
  count               = var.enable_detailed_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-webhook-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "N8N Webhook CPU utilization is above 80%"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.n8n_webhook.name
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-webhook-cpu-alarm"
    Service = "n8n-webhook"
  })
}

resource "aws_cloudwatch_metric_alarm" "webhook_memory_utilization" {
  count               = var.enable_detailed_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-webhook-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "N8N Webhook memory utilization is above 85%"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.n8n_webhook.name
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-webhook-memory-alarm"
    Service = "n8n-webhook"
  })
}

resource "aws_cloudwatch_metric_alarm" "webhook_running_task_count" {
  count               = var.enable_detailed_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-webhook-running-tasks"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.desired_count_webhook
  alarm_description   = "N8N Webhook running tasks below desired count"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.n8n_webhook.name
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-webhook-tasks-alarm"
    Service = "n8n-webhook"
  })
}

# ===================================================================
# ALARMS FOR REDIS SERVICE
# ===================================================================

resource "aws_cloudwatch_metric_alarm" "redis_cpu_utilization" {
  count               = var.enable_detailed_alarms && !var.use_elasticache_saas ? 1 : 0
  alarm_name          = "${var.project_name}-redis-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Redis CPU utilization is above 80%"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.redis[0].name
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-redis-cpu-alarm"
    Service = "redis"
  })
}

resource "aws_cloudwatch_metric_alarm" "redis_memory_utilization" {
  count               = var.enable_detailed_alarms && !var.use_elasticache_saas ? 1 : 0
  alarm_name          = "${var.project_name}-redis-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Redis memory utilization is above 85%"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.redis[0].name
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-redis-memory-alarm"
    Service = "redis"
  })
}

resource "aws_cloudwatch_metric_alarm" "redis_running_task_count" {
  count               = var.enable_detailed_alarms && !var.use_elasticache_saas ? 1 : 0
  alarm_name          = "${var.project_name}-redis-running-tasks"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "Redis running tasks below desired count"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.redis[0].name
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-redis-tasks-alarm"
    Service = "redis"
  })
}

# ===================================================================
# ALARMS FOR ALB (Application Load Balancer)
# ===================================================================

resource "aws_cloudwatch_metric_alarm" "alb_response_time" {
  count               = var.enable_detailed_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-alb-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 5
  alarm_description   = "ALB response time is above 5 seconds"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-alb-response-time-alarm"
    Service = "alb"
  })
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  count               = var.enable_detailed_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 3
  alarm_description   = "ALB 5XX errors exceed 3 in 1 minute"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-alb-5xx-errors-alarm"
    Service = "alb"
  })
}

resource "aws_cloudwatch_metric_alarm" "alb_4xx_errors" {
  count               = var.enable_detailed_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-alb-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 20
  alarm_description   = "ALB 4XX errors exceed 20 in 1 minute"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-alb-4xx-errors-alarm"
    Service = "alb"
  })
}

# ===================================================================
# GLOBAL ECS CLUSTER ALARMS
# ===================================================================

resource "aws_cloudwatch_metric_alarm" "cluster_cpu_reservation" {
  count               = var.enable_detailed_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-cluster-cpu-reservation"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS Cluster CPU reservation is above 80%"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-cluster-cpu-reservation-alarm"
    Service = "ecs-cluster"
  })
}

resource "aws_cloudwatch_metric_alarm" "cluster_memory_reservation" {
  count               = var.enable_detailed_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-cluster-memory-reservation"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryReservation"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS Cluster memory reservation is above 80%"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-cluster-memory-reservation-alarm"
    Service = "ecs-cluster"
  })
}

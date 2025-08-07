variable "master_fargate_cpu" {
  description = "CPU units for Fargate tasks."
  type        = number
}

variable "master_fargate_memory" {
  description = "Memory (MB) for Fargate tasks."
  type        = number
}

variable "worker_fargate_cpu" {
  description = "CPU units for Fargate tasks."
  type        = number
}

variable "worker_fargate_memory" {
  description = "Memory (MB) for Fargate tasks."
  type        = number
}

variable "webhook_fargate_cpu" {
  description = "CPU units for Fargate tasks."
  type        = number
}

variable "webhook_fargate_memory" {
  description = "Memory (MB) for Fargate tasks."
  type        = number
}

variable "desired_count_master" {
  description = "Desired count for n8n master service."
  type        = number
}

variable "desired_count_worker" {
  description = "Desired count for n8n worker service."
  type        = number
}

variable "desired_count_webhook" {
  description = "Desired count for n8n webhook service."
  type        = number
}

variable "use_elasticache_saas" {
  description = "Whether to use ElastiCache SaaS or local Redis"
  type        = bool
  default     = false
}

variable "redis_endpoint" {
  description = "Redis endpoint hostname."
  type        = string
  default     = null
}



variable "db_endpoint" {
  description = "PostgreSQL endpoint hostname."
  type        = string
}

variable "db_name" {
  description = "Database name."
  type        = string
}

variable "db_username" {
  description = "DB username."
  type        = string
}

variable "db_password" {
  description = "DB password."
  type        = string
}

variable "aws_region" {
  description = "AWS region for log configuration."
  type        = string
}

variable "n8n_basic_auth_user" {
  description = "n8n basic auth username (optional)."
  type        = string
  default     = null
}

variable "n8n_basic_auth_password" {
  description = "n8n basic auth password (optional)."
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC ID for ECS tasks."
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs."
  type        = list(string)
}

variable "common_tags" {
  description = "Common tags for all resources."
  type        = map(string)
}

variable "db_endpoint_port" {
  description = "PostgreSQL endpoint port."
  type        = number
}

variable "log_retention_days" {
  description = "Log retention days."
  type        = number
  default     = 30
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
}

variable "autoscaling_worker_max_capacity" {
  description = "Maximum number of workers."
  type        = number
  default     = 10
}

variable "autoscaling_worker_min_capacity" {
  description = "Minimum number of workers."
  type        = number
  default     = 1
}

variable "autoscaling_webhook_max_capacity" {
  description = "Maximum number of webhooks."
  type        = number
  default     = 10
}

variable "autoscaling_webhook_min_capacity" {
  description = "Minimum number of webhooks."
  type        = number
  default     = 1
}

variable "zone_id" {
  description = "Route53 zone ID."
  type        = string
}

variable "project_name" {
  description = "Project name."
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
}

variable "acm_certificate_arn_webhook" {
  description = "ACM certificate ARN for HTTPS webhook listener"
  type        = string
}

variable "domain_master" {
  description = "Domain name for master."
  type        = string
}

variable "domain_webhook" {
  description = "Domain name for webhook."
  type        = string
}

variable "redis_image" {
  description = "The image to use for the Redis container."
  type        = string
}

variable "n8n_image" {
  description = "The image to use for the n8n container."
  type        = string
}

variable "n8n_encryption_key" {
  description = "The encryption key to use for the n8n container."
  type        = string
}

variable "n8n_runners_auth_token" {
  description = "The auth token to use for the n8n runners."
  type        = string
}

variable "n8n_log_level" {
  description = "The log level to use for the n8n container."
  type        = string
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN to send alarms to."
  type        = list(string)
}

variable "enable_detailed_alarms" {
  description = "Enable detailed CloudWatch alarms for all ECS services"
  type        = bool
  default     = true
}

variable "alb_master_internal" {
  description = "Whether the master ALB should be internal (true) or internet-facing (false)"
  type        = bool
  default     = false
}

variable "alb_webhook_internal" {
  description = "Whether the webhook ALB should be internal (true) or internet-facing (false)"
  type        = bool
  default     = false
}
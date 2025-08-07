# Production N8N deployment on AWS ECS Fargate
# 
# This configuration deploys n8n workflow automation platform using ECS Fargate
# with queue mode architecture for production workloads.
#
# Key features:
# - Separation of persistent and ephemeral resources
# - Queue-based workflow execution for horizontal scaling
# - Multi-AZ deployment for high availability
# - Comprehensive monitoring and alerting
# - Security best practices with VPC isolation
#
# Deployment sequence:
# 1. Deploy persistency/ module first (RDS and persistent resources)
# 2. Deploy this root module (ECS and networking resources)
#
# Architecture:
# - Master Service: Web UI, API, workflow management (single instance)
# - Worker Services: Workflow execution from Redis queue (auto-scaling)
# - Webhook Services: External webhook processing
# - Redis Queue: ElastiCache-based message broker
# - PostgreSQL: RDS-based persistent storage
# - Load Balancers: Separate ALBs for UI and webhooks

# Networking configuration
# Uses existing VPC infrastructure with proper subnet segmentation.
# Public subnets host load balancers, private subnets host application services.
module "networking" {
  source = "./modules/networking_existing"
  
  # VPC Configuration
  vpc_id = var.vpc_id
  
  # Subnet Configuration - ensures proper AZ distribution
  public_subnet_cidrs  = var.public_subnet_cidrs   # ALB placement
  private_subnet_cidrs = var.private_subnet_cidrs  # Container placement
  
  # Validation occurs within the module to ensure:
  # - VPC exists and has proper DNS configuration
  # - Subnets are distributed across availability zones
  # - CIDR blocks don't overlap and have sufficient capacity
}

# ===============================================================================
# SECRETS MANAGEMENT
# ===============================================================================
# Centralized secrets management using AWS Secrets Manager for secure handling
# of database credentials and encryption keys. This approach ensures:
# - Secrets are never stored in Terraform state
# - Automatic rotation capabilities
# - Audit trail via CloudTrail
# - Fine-grained IAM access controls
# ===============================================================================
module "secrets" {
  source = "./modules/secrets"
  
  secret_name = var.secret_name
  
  # Expected secret structure (JSON):
  # {
  #   "db_name": "n8n",
  #   "db_username": "n8n_user",
  #   "db_password": "secure_random_password",
  #   "n8n_encryption_key": "32_character_encryption_key",
  #   "n8n_runners_auth_token": "optional_runners_token"
  # }
}

# ===============================================================================
# REDIS CACHE LAYER (ELASTICACHE)
# ===============================================================================
# Managed Redis service for n8n's queue mode implementation. ElastiCache provides
# enterprise features including automatic failover, backup, monitoring, and
# security features that are critical for production workloads.
#
# Queue mode enables horizontal scaling by distributing workflow execution
# across multiple worker processes, improving both performance and reliability.
# ===============================================================================
module "redis" {
  source = "./modules/redis"
  count  = var.use_elasticache_saas ? 1 : 0
  
  # Network Configuration
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnets
  vpc_cidr   = module.networking.vpc_cidr
  
  # Instance Configuration
  redis_saas_node_type = var.redis_saas_node_type
  
  # Resource Naming and Tagging
  project_name = local.clean_project_name
  common_tags  = var.common_tags
  
  depends_on = [module.networking]
}

# ===============================================================================
# SSL/TLS CERTIFICATE MANAGEMENT
# ===============================================================================
# Automated SSL certificate provisioning and validation using AWS Certificate
# Manager. Certificates are validated via DNS challenge using Route53, ensuring
# secure HTTPS connectivity for all public endpoints.
#
# Multi-domain support allows separate certificates for master UI and webhook
# endpoints, enabling different security policies and access patterns.
# ===============================================================================
module "acm" {
  source = "./modules/acm"
  
  # Certificate Domains - extracted from domain mapping configuration
  domains = [for config in var.domain_mapping : config.hostname]
  
  # DNS Configuration
  zone_id = var.zone_id
  
  # Resource Configuration
  project_name = local.clean_project_name
  common_tags  = var.common_tags
  
  depends_on = [module.networking]
  
  providers = {
    aws.route53 = aws.route53  # Cross-account DNS support
  }
}

# ===============================================================================
# PERSISTENT DATA LAYER
# ===============================================================================
# Critical persistent resources managed separately to prevent accidental deletion
# during infrastructure updates. This includes RDS databases and any other stateful
# resources that must survive application redeployments.
#
# DEPLOYMENT STRATEGY:
# - Deploy persistency/ first: cd persistency && terraform apply
# - Deploy main infrastructure: terraform apply (from root)
#
# This separation enables safe infrastructure recreation while preserving data.
# ===============================================================================
module "persistency" {
  source = "./persistency"
  
  # Network Configuration
  vpc_id               = module.networking.vpc_id
  private_subnet_cidrs = var.private_subnet_cidrs
  
  # Database Configuration
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  
  # Optional Business Logic Database
  create_db_instance_class_business_logic   = var.create_db_instance_class_business_logic
  db_instance_class_business_logic          = var.db_instance_class_business_logic
  db_allocated_storage_business_logic       = var.db_allocated_storage_business_logic
  db_business_logic_backup_retention_period = var.db_business_logic_backup_retention_period
  
  # Primary Database Backup Configuration
  db_n8n_backup_retention_period = var.db_n8n_backup_retention_period
  
  # Secrets and Authentication
  secret_name = var.secret_name
  
  # Resource Configuration
  aws_region   = var.aws_region
  aws_profile  = var.aws_profile
  project_name = local.clean_project_name
  common_tags  = var.common_tags
  
  depends_on = [module.networking]
}

# ===============================================================================
# N8N APPLICATION PLATFORM (ECS FARGATE)
# ===============================================================================
# Complete n8n application stack deployment using ECS Fargate with queue mode
# architecture. This configuration implements production-ready patterns for
# scalability, reliability, and observability.
#
# SERVICE ARCHITECTURE:
# 
# Master Service (Fixed: 1 instance):
# - Serves web UI and API endpoints
# - Handles workflow design and testing
# - Manages user authentication and system configuration
# - Single instance to maintain UI state consistency
#
# Worker Services (Auto-scaling: 2-20 instances):
# - Execute production workflows from Redis queue
# - Handle scheduled and webhook-triggered workflows
# - Scale based on CPU utilization for optimal performance
# - Stateless design enables horizontal scaling
#
# Webhook Services (Configurable: 1-3 instances):
# - Dedicated processors for external webhook requests
# - Separate from master to prevent UI performance impact
# - Load balanced for high availability
# - Scale based on webhook volume requirements
#
# NETWORKING AND SECURITY:
# - All containers deployed in private subnets
# - Load balancers in public subnets with SSL termination
# - Security groups implement least-privilege access
# - DNS records automatically created in Route53
# ===============================================================================
module "n8n" {
  source = "./modules/ecs"
  
  # Regional Configuration
  aws_region = var.aws_region
  
  # Master Service Configuration
  master_fargate_cpu    = var.master_fargate_cpu
  master_fargate_memory = var.master_fargate_memory
  desired_count_master  = var.desired_count_master
  
  # Worker Service Configuration (Auto-scaling)
  worker_fargate_cpu              = var.worker_fargate_cpu
  worker_fargate_memory           = var.worker_fargate_memory
  desired_count_worker            = var.desired_count_worker
  autoscaling_worker_max_capacity = var.autoscaling_worker_max_capacity
  autoscaling_worker_min_capacity = var.autoscaling_worker_min_capacity
  
  # Webhook Service Configuration
  webhook_fargate_cpu    = var.webhook_fargate_cpu
  webhook_fargate_memory = var.webhook_fargate_memory
  desired_count_webhook  = var.desired_count_webhook
  
  # Database Connectivity
  db_endpoint      = module.persistency.rds_endpoint
  db_endpoint_port = module.persistency.rds_port
  db_name          = module.secrets.secret_json["db_name"]
  db_username      = module.secrets.secret_json["db_username"]
  db_password      = module.secrets.secret_json["db_password"]
  
  # Redis Configuration
  use_elasticache_saas = var.use_elasticache_saas
  redis_endpoint       = var.use_elasticache_saas ? module.redis[0].redis_endpoint : null
  
  # Network Configuration
  vpc_id             = module.networking.vpc_id
  vpc_cidr           = module.networking.vpc_cidr
  public_subnet_ids  = module.networking.public_subnets
  private_subnet_ids = module.networking.private_subnets
  
  # SSL/TLS Configuration
  acm_certificate_arn         = module.acm.certificate_arns[var.domain_mapping["master"].hostname]
  acm_certificate_arn_webhook = module.acm.certificate_arns[var.domain_mapping["webhook"].hostname]
  
  # Domain Configuration
  domain_master  = var.domain_mapping["master"].hostname
  domain_webhook = var.domain_mapping["webhook"].hostname
  
  # Load Balancer Configuration
  alb_master_internal  = var.domain_mapping["master"].internal
  alb_webhook_internal = var.domain_mapping["webhook"].internal
  
  # Application Configuration
  n8n_encryption_key     = module.secrets.secret_json["n8n_encryption_key"]
  n8n_runners_auth_token = module.secrets.secret_json["n8n_runners_auth_token"]
  n8n_log_level          = var.n8n_log_level
  
  # Container Images
  n8n_image   = var.n8n_image
  redis_image = var.redis_image
  
  # DNS Configuration
  zone_id = var.zone_id
  
  # Observability Configuration
  log_retention_days     = var.log_retention_days
  enable_detailed_alarms = var.enable_detailed_alarms
  alarm_sns_topic_arn    = var.alarm_sns_topic_arn
  
  # Resource Configuration
  project_name = local.clean_project_name
  common_tags  = var.common_tags
  
  # Module Dependencies
  depends_on = [
    module.networking,
    module.secrets,
    module.persistency,
    module.redis,
    module.acm
  ]
  
  providers = {
    aws.route53 = aws.route53  # Cross-account DNS support
  }
}

# ===============================================================================
# LOCAL VALUES AND COMPUTED RESOURCES
# ===============================================================================
# Transformation of user-provided values into AWS resource-compatible formats
# with proper validation and length constraints.
# ===============================================================================
locals {
  # Sanitize project name for AWS resource naming constraints
  # - Maximum 20 characters to prevent resource name length issues
  # - Replace non-alphanumeric characters with hyphens
  # - Used as prefix for all AWS resources
  clean_project_name = substr(replace(var.project_name, "/[^a-zA-Z0-9]/", "-"), 0, 20)
}
# ===============================================================================
# N8N ECS TERRAFORM MODULE - VARIABLE DEFINITIONS
# ===============================================================================
# 
# Production-ready variable definitions for deploying n8n workflow automation
# platform on AWS ECS Fargate with queue mode architecture. This configuration
# supports enterprise-scale deployments with high availability, auto-scaling,
# and comprehensive monitoring capabilities.
#
# VARIABLE CATEGORIES:
# - AWS Provider Configuration: Region, profile, and cross-account setup
# - Network Infrastructure: VPC, subnets, and security boundaries
# - Domain and DNS: Route53 zones, SSL certificates, and endpoints
# - Database Configuration: RDS PostgreSQL with backup strategies
# - Container Platform: ECS Fargate resource allocation and scaling
# - Application Settings: n8n configuration, images, and performance
# - Monitoring and Logging: CloudWatch metrics, alarms, and retention
# - Security and Compliance: IAM, encryption, secrets management
#
# DEPLOYMENT PATTERNS SUPPORTED:
# - Enterprise Multi-Account: Separated security domains for infrastructure/DNS
# - Single Account: Unified management with proper IAM segmentation
# - Development Environment: Cost-optimized with reduced redundancy
# - Production Environment: High availability with auto-scaling capabilities
#
# OPERATIONAL CONSIDERATIONS:
# - All variables include comprehensive descriptions and validation rules
# - Resource naming follows AWS best practices for automation and governance
# - Configuration supports blue/green deployments and infrastructure updates
# - Scaling parameters enable workload-based resource optimization
# ===============================================================================

# ===================================================================
# LOCAL VALUE TRANSFORMATIONS
# ===================================================================
# Transforms user-provided project names into AWS resource-compatible
# formats with length and character restrictions.
# ===================================================================
locals {
  # AWS resource names: alphanumeric + hyphens only, max 20 chars
  clean_project_name            = substr(replace(var.project_name, "/[^a-zA-Z0-9]/", "-"), 0, 20)
  # Alternative format: underscores for resources that support them
  clean_project_name_underscore = replace(var.project_name, "/[^a-zA-Z0-9]/", "_")
}

# ===================================================================
# AWS PROVIDER CONFIGURATION
# ===================================================================
# Multi-provider setup supports organizations with separate AWS accounts
# for infrastructure and DNS management.
# ===================================================================

variable "aws_region" {
  description = "AWS region for main infrastructure deployment (ECS, RDS, ElastiCache)"
  type        = string
  
  # Common choices:
  # - us-east-1: Lowest latency for global users, ACM free tier
  # - eu-west-1: GDPR compliance, European users
  # - us-west-2: West coast users, disaster recovery from us-east-1
}

variable "aws_profile" {
  description = "AWS CLI profile for main infrastructure account"
  type        = string
  
  # Profile should have permissions for:
  # - ECS (Fargate tasks, services, clusters)
  # - RDS (databases, subnet groups, security groups)
  # - ElastiCache (Redis clusters)
  # - VPC (security groups, if creating networking)
  # - IAM (service roles, task roles)
  # - CloudWatch (logs, metrics, alarms)
  # - Secrets Manager (read access for database credentials)
}

variable "aws_region_route53" {
  description = "AWS region for Route53 operations (can be different from main region)"
  type        = string
  
  # Note: Route53 is a global service, but some operations require
  # a specific region context. us-east-1 is recommended for Route53.
}

variable "aws_profile_route53" {
  description = "AWS CLI profile for DNS management account (supports cross-account DNS)"
  type        = string
  
  # Use cases:
  # - Same as aws_profile: Single AWS account for all resources
  # - Different profile: Dedicated DNS management account for security/governance
  # 
  # Profile should have permissions for:
  # - Route53 (hosted zones, record sets)
  # - ACM (certificate validation via DNS)
}

# ===================================================================
# PROJECT CONFIGURATION
# ===================================================================

variable "project_name" {
  description = "Project identifier used as prefix for all AWS resources"
  type        = string
  
  # Naming considerations:
  # - Will be sanitized to alphanumeric + hyphens for AWS resources
  # - Keep under 20 characters to avoid resource name length limits
  # - Use descriptive names: "n8n-prod", "workflow-staging", etc.
  # 
  # Examples:
  # - "n8n-prod" -> n8n-prod-ecs-cluster, n8n-prod-master-alb
  # - "automation-dev" -> automation-dev-worker-service
}

# ===================================================================
# NETWORKING CONFIGURATION
# ===================================================================
# Uses existing VPC infrastructure. Ensure proper subnet configuration
# for security and availability.
# ===================================================================

variable "vpc_id" {
  description = "Existing VPC ID for n8n deployment"
  type        = string
  
  # Requirements:
  # - Internet Gateway attached (for ALB internet access)
  # - DNS hostnames enabled (for Route53 integration)
  # - DNS resolution enabled (for service discovery)
  # - Sufficient IP space for containers and load balancers
}

variable "az_count" {
  description = "Number of Availability Zones for multi-AZ deployment"
  type        = number
  
  # Recommendations:
  # - Minimum 2 AZs for high availability
  # - 3 AZs for maximum resilience (recommended for production)
  # - Match the number of public/private subnet CIDRs provided
  # 
  # Cost vs Availability:
  # - 2 AZs: Lower cost, basic HA
  # - 3 AZs: Higher cost, maximum resilience, supports database multi-AZ
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (ALB placement)"
  type        = list(string)
  
  # Purpose: Host Application Load Balancers for internet-facing traffic
  # 
  # Requirements:
  # - One CIDR per availability zone
  # - Route to Internet Gateway for inbound traffic
  # - Sufficient IP space for ALB (recommend /24 minimum)
  # - Should NOT host application containers (security best practice)
  # 
  # Example for 3 AZs in 10.0.0.0/16 VPC:
  # ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (container and database placement)"
  type        = list(string)
  
  # Purpose: Host ECS containers, RDS databases, ElastiCache clusters
  # 
  # Requirements:
  # - One CIDR per availability zone
  # - Route to NAT Gateway/Instance for outbound internet access
  # - Larger IP space for containers (recommend /24 or larger)
  # - No direct internet access (security isolation)
  # 
  # Example for 3 AZs in 10.0.0.0/16 VPC:
  # ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

# ===================================================================
# DATABASE CONFIGURATION (PRIMARY N8N DATABASE)
# ===================================================================
# PostgreSQL database for n8n workflows, executions, and user data.
# Managed by AWS RDS with automated backups and multi-AZ support.
# ===================================================================

variable "db_instance_class" {
  description = "RDS instance class for primary n8n database"
  type        = string
  
  # Instance class recommendations by environment:
  # 
  # Development/Testing:
  # - db.t3.micro: 1 vCPU, 1 GB RAM - minimal cost for dev
  # - db.t3.small: 1 vCPU, 2 GB RAM - light testing loads
  # 
  # Staging:
  # - db.t3.medium: 2 vCPU, 4 GB RAM - production-like testing
  # - db.t3.large: 2 vCPU, 8 GB RAM - performance testing
  # 
  # Production:
  # - db.r5.large: 2 vCPU, 16 GB RAM - memory-optimized for workflows
  # - db.r5.xlarge: 4 vCPU, 32 GB RAM - high-volume workflow processing
  # - db.r5.2xlarge: 8 vCPU, 64 GB RAM - enterprise-scale deployments
  # 
  # Note: Instance class can be changed with brief downtime for scaling
}

variable "db_allocated_storage" {
  description = "Initial storage allocation for primary n8n database (GB)"
  type        = number
  
  # Storage recommendations:
  # - Development: 20-50 GB (minimal workflow storage)
  # - Staging: 50-100 GB (testing with realistic data volumes)
  # - Production: 100-500 GB+ (depends on workflow complexity and retention)
  # 
  # Storage considerations:
  # - Can be increased without downtime (cannot be decreased)
  # - RDS auto-scaling available for production (configure separately)
  # - Monitor free storage space via CloudWatch alarms
  # - Execution history grows over time (plan for growth)
}

# ===================================================================
# ECS FARGATE RESOURCE CONFIGURATION
# ===================================================================
# Container resource allocation for each n8n service component.
# Fargate requires specific CPU/Memory combinations.
# ===================================================================

variable "master_fargate_cpu" {
  description = "CPU units for n8n master service (UI and API)"
  type        = number
  
  # Master service handles:
  # - Web UI serving and user interactions
  # - API requests for workflow management
  # - Test workflow executions
  # - User authentication and session management
  # 
  # CPU recommendations:
  # - Development: 256-512 (light UI usage)
  # - Staging: 512-1024 (testing and demos)
  # - Production: 1024-2048 (multiple concurrent users)
  # 
  # Note: Master is single instance, size based on concurrent UI users
}

variable "master_fargate_memory" {
  description = "Memory (MB) for n8n master service"
  type        = number
  
  # Memory recommendations by CPU:
  # - 256 CPU: 512-2048 MB
  # - 512 CPU: 1024-4096 MB
  # - 1024 CPU: 2048-8192 MB
  # - 2048 CPU: 4096-16384 MB
  # 
  # Considerations:
  # - n8n UI is memory-intensive for complex workflows
  # - Test executions run on master (size accordingly)
  # - Monitor memory utilization and adjust as needed
}

variable "worker_fargate_cpu" {
  description = "CPU units for n8n worker services (workflow execution)"
  type        = number
  
  # Worker services handle:
  # - Production workflow execution from Redis queue
  # - Scheduled workflow processing
  # - Heavy computational tasks
  # - External API integrations
  # 
  # CPU recommendations:
  # - Development: 512 (simple workflows)
  # - Staging: 1024 (production-like workflows)
  # - Production: 2048+ (complex workflows, high throughput)
  # 
  # Scaling strategy: Multiple workers auto-scale based on CPU usage
}

variable "worker_fargate_memory" {
  description = "Memory (MB) for n8n worker services"
  type        = number
  
  # Memory requirements depend on:
  # - Workflow complexity and data processing
  # - Number of parallel executions per worker
  # - External library dependencies
  # - Temporary data storage during execution
  # 
  # Monitor memory usage patterns and adjust scaling policies accordingly
}

variable "webhook_fargate_cpu" {
  description = "CPU units for n8n webhook services (external integrations)"
  type        = number
  
  # Webhook services handle:
  # - External webhook requests (production workloads)
  # - API endpoint for external system integrations
  # - High-frequency trigger processing
  # 
  # CPU recommendations:
  # - Development: 256-512 (low webhook volume)
  # - Production: 1024+ (high webhook frequency)
  # 
  # Size based on webhook frequency and response time requirements
}

variable "webhook_fargate_memory" {
  description = "Memory (MB) for n8n webhook services"
  type        = number
  
  # Webhook memory requirements:
  # - Lower than workers (simpler processing)
  # - Buffer for concurrent webhook requests
  # - Fast response times require adequate memory
}

# ===================================================================
# ECS SERVICE SCALING CONFIGURATION
# ===================================================================
# Controls the number of container instances for each service type.
# ===================================================================

variable "desired_count_master" {
  description = "Desired count for n8n master service (should always be 1)"
  type        = number
  
  # Master service scaling:
  # - ALWAYS set to 1 (single instance required)
  # - Master handles UI state and coordination
  # - Multiple masters can cause conflicts and data corruption
  # - Scale vertically (CPU/memory) instead of horizontally
  # 
  # High availability: Database and Redis provide persistence,
  # ECS will restart master if it fails
}

variable "desired_count_worker" {
  description = "Initial desired count for n8n worker services (auto-scaling enabled)"
  type        = number
  
  # Worker service scaling:
  # - Recommended minimum: 2 (for redundancy)
  # - Auto-scaling range controlled by min/max capacity variables
  # - Workers scale based on CPU utilization metrics
  # - More workers = higher workflow throughput
  # 
  # Scaling considerations:
  # - Start conservative and monitor queue depth
  # - Each worker can handle multiple concurrent workflows
  # - Scale out for parallel processing, scale up for complex workflows
}

variable "desired_count_webhook" {
  description = "Desired count for n8n webhook services"
  type        = number
  
  # Webhook service scaling:
  # - Recommended: 1-3 instances based on webhook volume
  # - Fixed scaling (no auto-scaling configured)
  # - Size based on webhook frequency and response time SLAs
  # 
  # Scaling guidelines:
  # - 1 instance: Low webhook volume (< 100/min)
  # - 2 instances: Medium webhook volume (100-1000/min)
  # - 3+ instances: High webhook volume (> 1000/min)
}

# ===================================================================
# REDIS CONFIGURATION
# ===================================================================
# Choose between managed ElastiCache (recommended) or containerized Redis
# ===================================================================

variable "use_elasticache_saas" {
  description = "Use managed ElastiCache Redis (true) or ECS container Redis (false)"
  type        = bool
  
  # ElastiCache (recommended for production):
  # - Managed service with automatic failover
  # - Built-in monitoring and alerting
  # - Automatic backups and patching
  # - Multi-AZ deployment for high availability
  # - Better performance and reliability
  # 
  # ECS Container Redis (development only):
  # - Lower cost for development environments
  # - Single point of failure
  # - Manual backup and maintenance
  # - Not recommended for production workloads
  # 
  # Recommendation: Always use true (ElastiCache) for production
}

variable "redis_saas_node_type" {
  description = "ElastiCache Redis node type (when use_elasticache_saas = true)"
  type        = string
  
  # Node type recommendations:
  # - cache.t3.micro: Development (0.5 GB RAM)
  # - cache.t3.small: Light production (1.37 GB RAM)
  # - cache.r5.large: Production (13.07 GB RAM)
  # - cache.r5.xlarge: High-volume production (26.32 GB RAM)
  # 
  # Sizing considerations:
  # - Queue depth depends on workflow execution time vs arrival rate
  # - Monitor queue length and memory utilization
  # - Redis is memory-based, size for peak queue depth
}

# ===================================================================
# COMMON CONFIGURATION
# ===================================================================

variable "common_tags" {
  description = "Common resource tags applied to all AWS resources"
  type        = map(string)
  
  # Recommended tag structure:
  # {
  #   Environment = "production|staging|development"
  #   Project     = "n8n-automation"
  #   Owner       = "platform-team"
  #   ManagedBy   = "terraform"
  #   CostCenter  = "engineering"
  #   Backup      = "required|not-required"
  # }
  # 
  # Tags enable:
  # - Cost allocation and reporting
  # - Resource organization and search
  # - Automation and lifecycle management
  # - Compliance and governance
}

variable "log_retention_days" {
  description = "CloudWatch log retention period for all services"
  type        = number
  default     = 30
  
  # Retention recommendations by environment:
  # - Development: 7 days (cost optimization)
  # - Staging: 30 days (debugging and analysis)
  # - Production: 90-365 days (compliance and troubleshooting)
  # 
  # Cost considerations:
  # - Longer retention = higher CloudWatch costs
  # - Archival options: Export to S3 for long-term storage
  # - Compliance requirements may dictate minimum retention
}


# ===================================================================
# AUTO-SCALING CONFIGURATION
# ===================================================================
# Worker auto-scaling based on CPU utilization for handling variable workloads
# ===================================================================

variable "autoscaling_worker_max_capacity" {
  description = "Maximum number of worker instances (auto-scaling upper limit)"
  type        = number
  default     = 10
  
  # Maximum capacity considerations:
  # - Set based on maximum expected workflow volume
  # - Consider cost implications of maximum scale-out
  # - Monitor actual usage to optimize limits
  # 
  # Recommendations by environment:
  # - Development: 3-5 (cost control)
  # - Staging: 5-10 (realistic testing)
  # - Production: 10-50+ (based on business requirements)
  # 
  # Warning: High max capacity can lead to unexpected costs during traffic spikes
}

variable "autoscaling_worker_min_capacity" {
  description = "Minimum number of worker instances (auto-scaling lower limit)"
  type        = number
  default     = 1
  
  # Minimum capacity ensures:
  # - Always available workers for immediate task processing
  # - Reduced cold start delays for workflow execution
  # - Basic redundancy and fault tolerance
  # 
  # Recommendations:
  # - Development: 1 (cost optimization)
  # - Production: 2+ (redundancy and immediate availability)
  # 
  # Cost vs Availability trade-off: Higher minimum = higher baseline cost
}

variable "autoscaling_worker_cpu_target" {
  description = "Target CPU utilization percentage for worker auto-scaling"
  type        = number
  default     = 60.0
  
  # CPU target tuning:
  # - Lower values (30-50%): More responsive scaling, higher costs
  # - Higher values (70-80%): More cost-effective, potential latency during spikes
  # - Recommended: 60% balances responsiveness and cost
  # 
  # Considerations:
  # - n8n workers can handle CPU spikes well
  # - Monitor actual CPU patterns and adjust accordingly
  # - Consider workflow execution time patterns
  # 
  # Note: Scaling decisions are based on average CPU over evaluation period
}

# ===================================================================
# DNS AND DOMAIN CONFIGURATION
# ===================================================================
# Route53 and SSL certificate configuration for n8n services
# ===================================================================

variable "zone_id" {
  description = "Route53 hosted zone ID for domain management"
  type        = string
  
  # Requirements:
  # - Hosted zone must exist and be properly configured
  # - DNS delegation must be set up (NS records)
  # - Zone can be in same or different AWS account (use route53 provider)
  # 
  # To find zone ID:
  # aws route53 list-hosted-zones --query "HostedZones[?Name=='your-domain.com.'].Id"
  # 
  # Note: Zone ID format is typically /hostedzone/Z1234567890ABC
}

variable "domain_mapping" {
  description = "Domain configuration for n8n services with ALB placement settings"
  type = map(object({
    hostname = string
    internal = bool
  }))
  
  validation {
    condition = (
      contains(keys(var.domain_mapping), "master") &&
      contains(keys(var.domain_mapping), "webhook")
    )
    error_message = "The domain_mapping must contain both 'master' and 'webhook' keys."
  }
  
  # Required structure:
  # {
  #   master = {
  #     hostname = "n8n.company.com"      # Main UI and API domain
  #     internal = false                  # true = internal ALB, false = internet-facing
  #   }
  #   webhook = {
  #     hostname = "webhook.company.com"  # Production webhook endpoint
  #     internal = false                  # typically false for external integrations
  #   }
  # }
  # 
  # Domain considerations:
  # - All domains must be within the specified Route53 hosted zone
  # - SSL certificates will be automatically generated and validated
  # - internal = true: ALB only accessible from within VPC
  # - internal = false: ALB accessible from internet (requires public subnets)
  # 
  # Security recommendations:
  # - Use internal = true for master if only internal access needed
  # - Consider using internal = true for webhook with VPN/private connectivity
  # - Always use HTTPS (enforced by ACM integration)
}

# ===================================================================
# CONTAINER IMAGE CONFIGURATION
# ===================================================================
# Docker image specifications for n8n and Redis containers
# ===================================================================

variable "n8n_image" {
  description = "Docker image for n8n application containers"
  type        = string
  
  # Image recommendations:
  # - Production: Pin to specific version (e.g., "n8nio/n8n:1.0.5")
  # - Staging: Use latest stable version for testing
  # - Development: "n8nio/n8n:latest" for latest features
  # 
  # Version management:
  # - Always test new versions in staging first
  # - Monitor n8n release notes for breaking changes
  # - Consider security updates and patch versions
  # 
  # Registry options:
  # - Docker Hub: n8nio/n8n (official images)
  # - ECR: Custom images with organization-specific modifications
}

variable "redis_image" {
  description = "Docker image for Redis container (when use_elasticache_saas = false)"
  type        = string
  
  # Redis image recommendations:
  # - Recommended: "redis:7-alpine" (official, lightweight)
  # - Alternative: "redis:7" (official, full features)
  # - Production: Pin to specific version (e.g., "redis:7.0.8-alpine")
  # 
  # Note: Only used when use_elasticache_saas = false
  # For production, always prefer ElastiCache over container Redis
}

# ===================================================================
# SECURITY AND SECRETS CONFIGURATION
# ===================================================================

variable "secret_name" {
  description = "AWS Secrets Manager secret name containing sensitive configuration"
  type        = string
  
  # Secret naming recommendations:
  # - Use descriptive, hierarchical names: "n8n/prod/credentials"
  # - Include environment: "n8n/staging/db", "n8n/dev/config"
  # - Follow organization naming conventions
  # 
  # Secret should contain JSON with required keys:
  # - db_name, db_username, db_password (database credentials)
  # - n8n_encryption_key (32-character string for n8n encryption)
  # - n8n_runners_auth_token (optional, for external runners)
  # 
  # Security best practices:
  # - Enable automatic rotation for database credentials
  # - Use separate secrets for different environments
  # - Monitor secret access via CloudTrail
  # - Grant minimal IAM permissions for secret access
}

variable "n8n_log_level" {
  description = "n8n application log level for troubleshooting and monitoring"
  type        = string
  
  # Log level options:
  # - "error": Only errors (minimal logging)
  # - "warn": Warnings and errors (recommended for production)
  # - "info": Informational messages (good for staging)
  # - "debug": Detailed debugging (development only)
  # - "verbose": Maximum logging (troubleshooting only)
  # 
  # Considerations:
  # - Higher verbosity = more CloudWatch costs
  # - Production recommendation: "warn" or "info"
  # - Use "debug" temporarily for troubleshooting
}

# ===================================================================
# MONITORING AND ALERTING CONFIGURATION
# ===================================================================
# CloudWatch alarms and notification setup for operational monitoring
# ===================================================================

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARNs for sending CloudWatch alarm notifications"
  type        = list(string)
  
  # SNS topic requirements:
  # - Must exist prior to deployment
  # - Should have appropriate subscribers (email, Slack, PagerDuty, etc.)
  # - Can be in same or different AWS region
  # 
  # Example ARN format:
  # ["arn:aws:sns:us-east-1:123456789012:n8n-alerts"]
  # 
  # Multiple topics supported for:
  # - Different notification channels (critical vs warning)
  # - Different teams (platform vs application)
  # - Different environments (prod alerts vs dev info)
  # 
  # To create SNS topic:
  # aws sns create-topic --name n8n-production-alerts
}

variable "enable_detailed_alarms" {
  description = "Enable comprehensive CloudWatch alarm monitoring"
  type        = bool
  default     = true
  
  # Detailed alarms include:
  # - ECS service CPU and memory utilization
  # - ALB target group healthy host count
  # - ALB response times and HTTP errors
  # - RDS connection count and CPU utilization
  # - ElastiCache memory utilization
  # 
  # Recommendations by environment:
  # - Production: true (full monitoring required)
  # - Staging: true (catch issues before production)
  # - Development: false (cost optimization)
  # 
  # Cost considerations:
  # - Each alarm has a small monthly cost
  # - Detailed monitoring provides early warning of issues
  # - Reduces mean time to resolution (MTTR)
}


# ===================================================================
# OPTIONAL BUSINESS LOGIC DATABASE CONFIGURATION
# ===================================================================
# Additional PostgreSQL database for custom business logic separation
# ===================================================================

variable "create_db_instance_class_business_logic" {
  description = "Enable optional business logic database (true/false as string)"
  type        = string
  
  # Use cases for separate business logic database:
  # - Isolate custom application data from n8n core data
  # - Different performance requirements (OLAP vs OLTP)
  # - Separate backup and recovery policies
  # - Different access patterns and user permissions
  # 
  # Set to "true" to create, "false" to skip
  # Note: Uses string type for conditional resource creation
}

variable "db_instance_class_business_logic" {
  description = "RDS instance class for optional business logic database"
  type        = string
  
  # Separate sizing from main n8n database allows:
  # - Cost optimization based on actual business logic usage
  # - Independent scaling based on workload patterns
  # - Different performance characteristics (CPU vs memory optimized)
  # 
  # Typically smaller than main n8n database unless heavily used
}

variable "db_allocated_storage_business_logic" {
  description = "Storage allocation for optional business logic database (GB)"
  type        = number
  
  # Sizing considerations:
  # - Start smaller than main database
  # - Size based on expected business logic data volume
  # - Can be increased without downtime as needed
}

# ===================================================================
# DATABASE BACKUP CONFIGURATION
# ===================================================================
# Automated backup settings for data protection and compliance
# ===================================================================

variable "db_n8n_backup_retention_period" {
  description = "Automated backup retention period for primary n8n database (days)"
  type        = number
  
  # Backup retention recommendations:
  # - Development: 1-3 days (minimal retention for cost)
  # - Staging: 7 days (sufficient for testing scenarios)
  # - Production: 7-35 days (based on business requirements)
  # 
  # Considerations:
  # - Longer retention = higher storage costs
  # - Compliance requirements may dictate minimum retention
  # - Point-in-time recovery available within retention period
  # - Automatic daily backups with configurable window
  # - Cross-region backup replication available (configure separately)
}

variable "db_business_logic_backup_retention_period" {
  description = "Automated backup retention period for business logic database (days)"
  type        = number
  
  # Business logic database backup considerations:
  # - Can be different from main n8n database
  # - Base on criticality of business logic data
  # - Consider data change frequency and recovery requirements
  # - May require longer retention for analytical workloads
  # 
  # Backup strategy alignment:
  # - Coordinate with main database backup schedule
  # - Consider cross-database consistency requirements
  # - Plan for disaster recovery scenarios
}
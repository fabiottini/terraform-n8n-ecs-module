# ===============================================================================
# N8N TERRAFORM MODULE OUTPUTS
# ===============================================================================
#
# Comprehensive output definitions that provide essential information about
# deployed infrastructure for operational procedures, monitoring integration,
# and system interconnection.
#
# OUTPUT CATEGORIES:
# - Network Infrastructure: VPC and subnet information
# - Security Resources: Secret ARNs and access information
# - Application Endpoints: Service URLs and connection details
# - Operational Data: Resource identifiers for troubleshooting
#
# These outputs support:
# - Integration with other Terraform modules
# - CI/CD pipeline configuration and validation
# - Monitoring and alerting system setup
# - Operational procedures and troubleshooting
# - Cost allocation and resource management
# ===============================================================================

# ===============================================================================
# NETWORK INFRASTRUCTURE OUTPUTS
# ===============================================================================
# Core networking information required for system integration and expansion.
# These outputs enable other infrastructure components to connect properly
# to the n8n deployment while maintaining security boundaries.
# ===============================================================================

output "vpc_id" {
  description = "VPC identifier where n8n infrastructure is deployed"
  value       = module.networking.vpc_id
  
  # Operational uses:
  # - Security group rule references for additional services
  # - VPC peering and transit gateway configurations
  # - Network troubleshooting and documentation
  # - Resource organization and cost allocation
}

output "vpc_cidr" {
  description = "VPC CIDR block for network planning and security configuration"
  value       = module.networking.vpc_cidr
  
  # Operational uses:
  # - Security group rules allowing VPC-wide communication
  # - Network Access Control List (NACL) configurations
  # - VPC peering and interconnection planning
  # - IP address conflict prevention and subnet planning
}

output "public_subnet_ids" {
  description = "Public subnet identifiers hosting internet-facing load balancers"
  value       = module.networking.public_subnets
  
  # Operational uses:
  # - Additional Application Load Balancer deployments
  # - NAT Gateway placement for other services
  # - Network Load Balancer configurations
  # - Internet Gateway route management
}

output "private_subnet_ids" {
  description = "Private subnet identifiers hosting application containers and databases"
  value       = module.networking.private_subnets
  
  # Operational uses:
  # - ECS service deployments for additional applications
  # - RDS database subnet group references
  # - ElastiCache cluster placement
  # - Lambda function VPC configurations
}

# ===============================================================================
# SECURITY AND SECRETS OUTPUTS
# ===============================================================================
# Security-related outputs with appropriate sensitivity markings to prevent
# exposure of sensitive data while providing necessary access information
# for operational procedures.
# ===============================================================================

output "secret_arn" {
  description = "AWS Secrets Manager secret ARN containing n8n configuration"
  value       = module.secrets.secret_arn
  
  # Operational uses:
  # - IAM policy creation for applications requiring secret access
  # - Cross-account secret sharing and permissions
  # - CloudTrail monitoring of secret access patterns
  # - Backup and disaster recovery procedure documentation
  # 
  # Security note: ARN is safe to expose (contains no secret values)
}

output "secret_string" {
  description = "Complete secret string from AWS Secrets Manager (JSON format)"
  value       = module.secrets.secret_string
  sensitive   = true
  
  # WARNING: Contains highly sensitive data
  # - Database passwords and encryption keys
  # - Authentication tokens and API keys
  # - Only access in secure, authenticated contexts
  # - Never expose in CI/CD logs or unsecured outputs
  # 
  # Access pattern: terraform output -raw secret_string | jq '.key'
}

output "secret_json" {
  description = "Parsed secret JSON object for programmatic access"
  value       = module.secrets.secret_json
  sensitive   = true
  
  # WARNING: Contains highly sensitive data
  # - Structured access to individual secret components
  # - Use for conditional logic based on secret contents
  # - Maintain strict access controls and audit trails
  # 
  # Access pattern: terraform output -json secret_json | jq '.db_password'
}

# ===============================================================================
# APPLICATION ACCESS OUTPUTS
# ===============================================================================
# Service endpoint information for user access and system integration.
# These outputs provide the primary access points for the deployed n8n platform.
# ===============================================================================

output "n8n_master_url" {
  description = "Primary n8n web interface URL for workflow management and administration"
  value       = "https://${var.domain_mapping["master"].hostname}"
  
  # Primary access point for:
  # - Workflow design, testing, and management
  # - User authentication and account management
  # - System administration and configuration
  # - Manual workflow execution and debugging
  # - API access for programmatic workflow management
}

output "n8n_webhook_url" {
  description = "Production webhook endpoint URL for external system integrations"
  value       = "https://${var.domain_mapping["webhook"].hostname}"
  
  # Integration endpoint for:
  # - External system webhooks and callbacks
  # - Production workflow triggers from third-party services
  # - API integrations with business applications
  # - Monitoring and alerting system integrations
  # - Automated workflow execution from external events
}

# ===============================================================================
# OPERATIONAL INFRASTRUCTURE OUTPUTS
# ===============================================================================
# Resource identifiers and connection information for operational procedures,
# monitoring, and troubleshooting activities.
# ===============================================================================

output "ecs_cluster_name" {
  description = "ECS cluster identifier for direct AWS CLI operations and monitoring"
  value       = module.n8n.ecs_cluster_name
  
  # Operational uses:
  # - AWS CLI commands for service management
  # - CloudWatch metrics and log group references
  # - ECS Exec access for container troubleshooting
  # - Auto-scaling policy configurations
  # - Service discovery and load balancer target groups
}

output "rds_endpoint" {
  description = "PostgreSQL database endpoint for direct database operations"
  value       = module.persistency.rds_endpoint
  
  # Operational uses:
  # - Database administration and maintenance tasks
  # - Backup and restore operations
  # - Performance monitoring and optimization
  # - Disaster recovery procedures
  # - Database connection troubleshooting
  # 
  # Security note: Endpoint is only accessible from within VPC
}

output "load_balancer_dns_names" {
  description = "Application Load Balancer DNS names for direct access and monitoring"
  value = {
    master  = module.n8n.master_alb_dns_name
    webhook = module.n8n.webhook_alb_dns_name
  }
  
  # Operational uses:
  # - Direct load balancer health checks and testing
  # - CloudWatch metrics and alarm configurations
  # - DNS troubleshooting and validation
  # - Performance testing and load analysis
  # - CDN and caching layer configurations
}

# ===============================================================================
# CONDITIONAL INFRASTRUCTURE OUTPUTS
# ===============================================================================
# Resource information that may or may not exist based on configuration options.
# ===============================================================================

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint for queue operations and monitoring"
  value       = var.use_elasticache_saas ? module.redis[0].redis_endpoint : "Container-based Redis (no external endpoint)"
  
  # Conditional output based on Redis deployment method:
  # - ElastiCache: Managed service endpoint for external monitoring
  # - Container: No external endpoint (internal ECS service)
  # 
  # Operational uses (ElastiCache only):
  # - Redis performance monitoring and optimization
  # - Queue depth analysis and alerting
  # - Network connectivity testing and troubleshooting
  # - Redis CLI access for debugging (via VPN/bastion)
}

# ===============================================================================
# TERRAFORM STATE INFORMATION
# ===============================================================================
# Metadata about the Terraform deployment for state management and validation.
# ===============================================================================

output "deployment_region" {
  description = "AWS region where the infrastructure is deployed"
  value       = var.aws_region
  
  # Operational uses:
  # - Multi-region deployment coordination
  # - Resource discovery and inventory management
  # - Cost allocation and regional analysis
  # - Disaster recovery planning and validation
}

output "project_identifier" {
  description = "Sanitized project name used for resource naming"
  value       = local.clean_project_name
  
  # Operational uses:
  # - Resource naming pattern validation
  # - Cost allocation tag verification
  # - Resource group organization
  # - Automated resource discovery and management
}
# Production-Ready n8n on AWS ECS

Enterprise-grade Terraform module for deploying [n8n](https://n8n.io) workflow automation platform on AWS using ECS Fargate with scalable queue-mode architecture.

## What is n8n?

n8n is a powerful workflow automation tool that helps you connect different services together. Think of it as a visual programming language for APIs - you can build complex automations without writing code by connecting different services like:

- **Data Synchronization**: Sync data between CRM systems, databases, and spreadsheets
- **Social Media Automation**: Post content across multiple platforms automatically
- **E-commerce Operations**: Automate order processing, inventory management, and customer communications
- **DevOps Workflows**: Automate deployments, monitoring alerts, and incident response
- **Business Process Automation**: Invoice processing, lead qualification, and reporting

Unlike cloud-based solutions like Zapier, n8n is self-hosted, giving you complete control over your data and workflows while supporting both no-code visual interfaces and custom JavaScript code execution.

## Architecture Overview

This module implements n8n's **queue mode** for distributed workflow execution, providing horizontal scalability, fault tolerance, and production-grade reliability. The architecture supports two Redis deployment options to meet different operational requirements.

### Option 1: Self-Managed Redis on ECS

Ideal for complete infrastructure control and cost optimization:

```
                             🌐 Internet
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
            ┌───────▼────────┐          ┌───────▼────────┐
            │  ALB Master    │          │  ALB Webhook   │
            │  🔐 SSL/TLS    │          │   🔐 SSL/TLS   │
            │n8n.domain.com  │          │webhook.domain.com│
            └───────┬────────┘          └───────┬────────┘
                    │                           │
        ┌───────────┴─────────────┬─────────────┴───────────┐
        │                         │                         │
        ▼                         ▼                         ▼
┌─────────────┐           ┌─────────────┐           ┌─────────────┐
│     AZ-A    │           │     AZ-B    │           │     AZ-C    │
├─────────────┤           ├─────────────┤           ├─────────────┤
│ Public      │           │ Public      │           │ Public      │
│ NAT Gateway │           │ NAT Gateway │           │ NAT Gateway │
├─────────────┤           ├─────────────┤           ├─────────────┤
│ Private     │           │ Private     │           │ Private     │
│             │           │             │           │             │
│ Master      │           │ Worker      │           │ Worker      │
│ Webhook     │           │ RDS         │           │ RDS         │
│ Redis       │           │ Primary     │           │ Standby     │
│             │           │             │           │             │
└─────────────┘           └─────────────┘           └─────────────┘

```

**Architecture Components:**
- **Master**: Single instance for UI/API (AZ-A)
- **Workers**: Auto-scaling 2-10 instances (AZ-B, AZ-C) 
- **Webhooks**: Auto-scaling instances (AZ-A)
- **Redis**: Queue management (AZ-A)
- **Database**: PostgreSQL Multi-AZ (Primary: AZ-B, Standby: AZ-C)

### Option 2: Managed Redis with ElastiCache (SaaS)

Recommended for production environments requiring managed services and high availability:

```
                              🌐 Internet
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
            ┌───────▼────────┐          ┌───────▼──────────┐
            │  ALB Master    │          │  ALB Webhook     │
            │ 🔐 SSL/TLS     │          │ 🔐 SSL/TLS       │
            │n8n.domain.com  │          │webhook.domain.com│
            └───────┬────────┘          └───────┬──────────┘
                    │                           │
        ┌───────────┴─────────────┬─────────────┴───────────┐
        │                         │                         │
        ▼                         ▼                         ▼
┌─────────────┐           ┌─────────────┐           ┌─────────────┐
│     AZ-A    │           │     AZ-B    │           │     AZ-C    │
├─────────────┤           ├─────────────┤           ├─────────────┤
│ Public      │           │ Public      │           │ Public      │
│ NAT Gateway │           │ NAT Gateway │           │ NAT Gateway │
├─────────────┤           ├─────────────┤           ├─────────────┤
│ Private     │           │ Private     │           │ Private     │
│             │           │             │           │             │
│ Master      │           │ Worker      │           │ Worker      │
│ Webhook     │           │ RDS         │           │ RDS         │
│             │           │ Primary     │           │ Standby     │
│             │           │             │           │             │
└─────────────┘           └─────────────┘           └─────────────┘
        │                         │                         │
        └─────────────────────────┴─────────────┬───────────┘
                                                │
                                           ┌────▼────────┐
                                           │☁️ Redis     │
                                           │ElastiCache  │
                                           │Multi-AZ     │
                                           └─────────────┘
```

**Architecture Components:**
- **Master**: Single instance for UI/API (AZ-A)
- **Workers**: Auto-scaling 2-10 instances (AZ-B, AZ-C) 
- **Webhooks**: Auto-scaling instances (AZ-A)
- **Redis**: ☁️ ElastiCache Multi-AZ cluster (Managed SaaS)
- **Database**: PostgreSQL Multi-AZ (Primary: AZ-B, Standby: AZ-C)

## Key Features

### 🚀 Production-Ready Architecture
- **Queue Mode Implementation**: Distributed n8n architecture for horizontal scalability
- **Multi-AZ Deployment**: Services deployed across 3 availability zones for maximum resilience
- **Auto-Scaling**: Webhook and Worker services automatically scale based on demand (2-10 instances)
- **High Availability Database**: RDS PostgreSQL with Multi-AZ deployment and automatic failover

### 🔒 Enterprise Security
- **Network Isolation**: All services deployed in private subnets with VPC isolation
- **SSL/TLS Termination**: Automatic certificate management through AWS Certificate Manager
- **Encryption**: Data encrypted in transit and at rest (RDS, ElastiCache)
- **Secrets Management**: Secure credential storage using AWS Secrets Manager
- **IAM Integration**: Least privilege access controls with dedicated service roles

### 📊 Scalability & Performance
- **Master Service**: Single instance for UI/API coordination and workflow management
- **Worker Services**: Auto-scaling from 2 to 10 instances based on CPU utilization
- **Webhook Services**: Configurable scaling for external webhook processing
- **Database**: RDS PostgreSQL optimized for workflow storage with configurable sizing
- **Queue Management**: Redis-based task distribution (ECS or ElastiCache options)

### 🔍 Monitoring & Observability
- **CloudWatch Integration**: Comprehensive metrics for all services and infrastructure
- **Automated Alerting**: Configurable SNS notifications for critical thresholds
- **Centralized Logging**: Structured logs with configurable retention policies
- **Performance Metrics**: Application-level and infrastructure-level monitoring

## Prerequisites

Before deploying this module, ensure you have:

- **Terraform** >= 1.3.0 installed
- **AWS CLI** configured with appropriate permissions
- **Existing VPC** with public/private subnets and NAT Gateway configured
- **Route53 Hosted Zone** for your domain
- **AWS Secrets Manager** access for credential storage

## Quick Start Guide

### Step 1: Create Required Secrets

Create an AWS Secrets Manager secret with your n8n configuration:

```bash
aws secretsmanager create-secret \
  --name "n8n/production/credentials" \
  --description "n8n production environment credentials" \
  --secret-string '{
    "db_name": "n8n",
    "db_username": "n8n_user", 
    "db_password": "your_secure_32_character_password_here",
    "n8n_encryption_key": "your_32_character_encryption_key_here",
    "n8n_runners_auth_token": "optional_token_for_external_runners"
  }'
```

**Security Note**: Generate strong passwords and encryption keys. The encryption key must be exactly 32 characters and will be used to encrypt/decrypt workflow data.

### Step 2: Configure Your Infrastructure

Create a `terraform.tfvars` file with your specific configuration:

```hcl
# ===========================
# AWS Account Configuration
# ===========================
aws_region  = "us-west-2"
aws_profile = "your-aws-profile"

# Route53 (can be in different account)
aws_region_route53  = "us-west-2"  
aws_profile_route53 = "your-dns-profile"

# ===========================
# Project Configuration
# ===========================
project_name = "n8n-production"

# ===========================
# Domain Configuration  
# ===========================
domain_mapping = {
  master = {
    hostname = "n8n.yourdomain.com"      # Main n8n UI
    internal = false                      # Public access
  }
  webhook = {
    hostname = "webhook.yourdomain.com"   # Webhook endpoints
    internal = false                      # Public access
  }
}

# ===========================
# Networking Configuration
# ===========================
vpc_id = "vpc-xxxxxxxxx"               # Your existing VPC ID
az_count = 3                           # Deploy across 3 AZs

# Private subnets for services
private_subnet_cidrs = [
  "10.0.1.0/24",   # AZ-a
  "10.0.2.0/24",   # AZ-b  
  "10.0.3.0/24"    # AZ-c
]

# Public subnets for load balancers
public_subnet_cidrs = [
  "10.0.101.0/24", # AZ-a
  "10.0.102.0/24", # AZ-b
  "10.0.103.0/24"  # AZ-c
]

# ===========================
# DNS & SSL Configuration
# ===========================
zone_id = "Z1234567890ABC"             # Route53 hosted zone ID

# ===========================
# Secrets Management
# ===========================
secret_name = "n8n/production/credentials"

# ===========================
# Database Configuration
# ===========================
db_instance_class = "db.r5.large"      # RDS instance type
db_allocated_storage = 100             # Storage in GB
db_n8n_backup_retention_period = 30   # Backup retention days

# ===========================
# Redis Configuration (Choose One)
# ===========================

# Option 1: Managed ElastiCache (Recommended)
use_elasticache_saas = true
redis_saas_node_type = "cache.r5.large"

# Option 2: Self-managed Redis on ECS
# use_elasticache_saas = false
# redis_image = "redis:7-alpine"

# ===========================
# ECS Configuration - Master
# ===========================
master_fargate_cpu    = 2048           # 2 vCPU
master_fargate_memory = 4096           # 4 GB RAM
desired_count_master  = 1              # Always 1 for coordination

# ===========================
# ECS Configuration - Workers (Auto-scaling)
# ===========================
worker_fargate_cpu              = 2048  # 2 vCPU per worker
worker_fargate_memory           = 4096  # 4 GB RAM per worker
desired_count_worker            = 2     # Initial worker count
autoscaling_worker_min_capacity = 2     # Minimum workers
autoscaling_worker_max_capacity = 10    # Maximum workers
autoscaling_worker_cpu_target   = 60.0  # CPU % target for scaling

# ===========================
# ECS Configuration - Webhooks (Auto-scaling)
# ===========================
webhook_fargate_cpu              = 1024 # 1 vCPU per webhook service
webhook_fargate_memory           = 2048 # 2 GB RAM per webhook service  
desired_count_webhook            = 2    # Initial webhook count
autoscaling_webhook_min_capacity = 2    # Minimum webhook services
autoscaling_webhook_max_capacity = 5    # Maximum webhook services

# ===========================
# Container Images
# ===========================
n8n_image   = "n8nio/n8n:latest"       # n8n Docker image
redis_image = "redis:7-alpine"         # Redis image (if using ECS Redis)

# ===========================
# Monitoring & Alerting
# ===========================
enable_detailed_alarms = true
alarm_sns_topic_arn = [
  "arn:aws:sns:us-west-2:123456789012:n8n-critical-alerts",
  "arn:aws:sns:us-west-2:123456789012:n8n-warning-alerts"
]
log_retention_days = 30                # CloudWatch log retention
n8n_log_level     = "info"            # n8n logging level

# ===========================
# Resource Tagging
# ===========================
common_tags = {
  Environment = "production"
  Project     = "n8n-automation"
  ManagedBy   = "terraform"
  Owner       = "platform-team"
}
```

### Step 3: Deploy Infrastructure

```bash
# Clone and enter the module directory
git clone <this-repository>
cd terraform-n8n-ecs-module

# Initialize Terraform
terraform init

# Deploy persistent resources (separate state)
cd persistency
terraform init
terraform plan -var-file="../terraform.tfvars"
terraform apply -var-file="../terraform.tfvars"
cd ..

# Deploy main infrastructure
terraform plan
terraform apply
```

### Step 4: Access Your n8n Instance

After deployment completes:

1. **n8n UI**: Access at `https://n8n.yourdomain.com`
2. **Webhook Endpoints**: Available at `https://webhook.yourdomain.com`
3. **Initial Setup**: Follow n8n's first-time setup wizard

## Architecture Deep Dive

### Service Components

| Component | Purpose | Scaling | Resource Allocation |
|-----------|---------|---------|-------------------|
| **Master** | Web UI, API, workflow coordination | Fixed (1 instance) | 2 vCPU, 4GB RAM |
| **Workers** | Workflow execution, queue processing | Auto-scale (2-10) | 2 vCPU, 4GB RAM each |
| **Webhooks** | External webhook processing | Auto-scale (2-5) | 1 vCPU, 2GB RAM each |
| **Database** | Workflow storage, user data | RDS Multi-AZ | Configurable |
| **Queue** | Task distribution | Redis (ECS/ElastiCache) | Configurable |

### Auto-Scaling Behavior

#### Worker Services
- **Scale Out**: When average CPU > 60% for 2 consecutive minutes
- **Scale In**: When average CPU < 30% for 5 consecutive minutes  
- **Limits**: 2 minimum, 10 maximum instances
- **Cooldown**: 300 seconds between scaling actions

#### Webhook Services  
- **Scale Out**: When average CPU > 70% for 2 consecutive minutes
- **Scale In**: When average CPU < 40% for 5 consecutive minutes
- **Limits**: 2 minimum, 5 maximum instances
- **Cooldown**: 300 seconds between scaling actions

### Database Architecture

- **Engine**: PostgreSQL 13+ with Multi-AZ deployment
- **Availability**: Primary instance in one AZ, standby in another
- **Backup**: Automated daily backups with configurable retention
- **Encryption**: Data encrypted at rest using AWS KMS
- **Monitoring**: CloudWatch metrics for connections, CPU, storage

### Security Model

#### Network Security
- All services deployed in private subnets
- Load balancers in public subnets only
- NAT Gateways for outbound internet access
- Security groups with least privilege rules

#### Data Security  
- SSL/TLS certificates auto-managed by ACM
- Database encryption at rest and in transit
- Redis encryption in transit (ElastiCache)
- Secrets stored in AWS Secrets Manager

#### Access Control
- Dedicated IAM roles for each service
- Cross-service communication via security groups
- No direct internet access for application services

## Configuration Reference

### Environment Variables

The module automatically configures n8n with the following environment variables:

```bash
# Core Configuration
N8N_PROTOCOL=https
N8N_HOST=n8n.yourdomain.com
N8N_PORT=5678
N8N_LISTEN_ADDRESS=0.0.0.0

# Database Configuration  
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=<rds-endpoint>
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=<from-secrets>
DB_POSTGRESDB_PASSWORD=<from-secrets>

# Queue Configuration
QUEUE_BULL_REDIS_HOST=<redis-endpoint>
QUEUE_BULL_REDIS_PORT=6379
EXECUTIONS_MODE=queue

# Security Configuration
N8N_ENCRYPTION_KEY=<from-secrets>
N8N_USER_MANAGEMENT_JWT_SECRET=<auto-generated>

# Performance Configuration
N8N_LOG_LEVEL=info
N8N_LOG_OUTPUT=console
GENERIC_TIMEZONE=UTC
```

### Scaling Configuration

Customize auto-scaling behavior:

```hcl
# Worker scaling thresholds
autoscaling_worker_cpu_target = 60.0    # Target CPU percentage
autoscaling_worker_min_capacity = 2     # Minimum instances  
autoscaling_worker_max_capacity = 10    # Maximum instances

# Webhook scaling thresholds
autoscaling_webhook_cpu_target = 70.0   # Target CPU percentage
autoscaling_webhook_min_capacity = 2    # Minimum instances
autoscaling_webhook_max_capacity = 5    # Maximum instances
```

### Monitoring Configuration

Configure alerting thresholds:

```hcl
enable_detailed_alarms = true

# SNS topics for different alert severities
alarm_sns_topic_arn = [
  "arn:aws:sns:region:account:critical-alerts",  # High priority
  "arn:aws:sns:region:account:warning-alerts"    # Low priority  
]

# CloudWatch log retention
log_retention_days = 30    # 30 days retention
```

## Monitoring and Alerting

### Built-in CloudWatch Alarms

The module creates the following alarms automatically:

#### ECS Service Alarms
- High CPU utilization (>80% for 5 minutes)
- High memory utilization (>85% for 5 minutes) 
- Service task failures
- Load balancer target health

#### Database Alarms
- High CPU utilization (>75% for 10 minutes)
- High connection count (>80% of max)
- Low free storage space (<20%)
- Replica lag (if applicable)

#### Redis Alarms (ElastiCache)
- High memory utilization (>80%)
- High CPU utilization (>75%)
- Connection failures
- Eviction events

### Custom Dashboards

Access pre-built CloudWatch dashboards:
- **n8n-overview**: High-level service health
- **n8n-performance**: Detailed performance metrics  
- **n8n-infrastructure**: AWS resource utilization

### Log Analysis

Query n8n logs using CloudWatch Insights:

```sql
# Find workflow execution errors
fields @timestamp, @message
| filter @message like /ERROR/
| filter @message like /execution/
| sort @timestamp desc
| limit 100

# Monitor webhook processing
fields @timestamp, @message  
| filter @message like /webhook/
| stats count() by bin(5m)

# Track auto-scaling events
fields @timestamp, @message
| filter @message like /scaling/
| sort @timestamp desc
```

## Operational Procedures

### Deployment Workflow

1. **Plan Changes**: Always run `terraform plan` first
2. **Stage Deployment**: Test in staging environment  
3. **Deploy Incrementally**: Apply changes during maintenance window
4. **Verify Health**: Check all services are healthy post-deployment
5. **Monitor**: Watch metrics for 30 minutes after deployment

### Scaling Operations

#### Manual Scaling
```bash
# Scale workers immediately
terraform apply -var="desired_count_worker=5"

# Update auto-scaling limits
terraform apply -var="autoscaling_worker_max_capacity=15"
```

#### Vertical Scaling
```bash  
# Increase worker resources
terraform apply -var="worker_fargate_cpu=4096" \
                -var="worker_fargate_memory=8192"
```

### Backup and Recovery

#### Database Backups
- **Automated**: Daily backups with configurable retention
- **Manual**: On-demand snapshots before major changes
- **Cross-Region**: Optional backup replication for DR

#### Recovery Procedures
1. **Database**: Restore from RDS snapshot
2. **Application**: Redeploy from Terraform state
3. **Configuration**: Restore secrets from backup
4. **DNS**: Update Route53 if needed

### Maintenance Tasks

#### Regular Maintenance
- **Weekly**: Review CloudWatch alarms and metrics
- **Monthly**: Update container images and security patches
- **Quarterly**: Review and rotate secrets
- **Annually**: Review and update backup retention policies

#### Security Updates
```bash
# Update n8n version
terraform apply -var="n8n_image=n8nio/n8n:1.x.x"

# Rotate database password
aws secretsmanager update-secret --secret-id n8n/production/credentials \
  --secret-string '{"db_password": "new_secure_password"}'
terraform apply  # Restart services to pick up new password
```

## Troubleshooting Guide

### Common Issues

#### Services Won't Start
**Symptoms**: ECS tasks failing to start or immediately stopping

**Diagnosis Steps**:
1. Check CloudWatch logs: `/aws/ecs/n8n-{service}`
2. Verify secrets are accessible: `aws secretsmanager get-secret-value`
3. Check security group rules allow database connections
4. Validate environment variable configuration

**Common Solutions**:
```bash
# Check service logs
aws logs filter-log-events --log-group-name /aws/ecs/n8n-master

# Verify database connectivity
aws rds describe-db-instances --db-instance-identifier n8n-production

# Check task definition
aws ecs describe-task-definition --task-definition n8n-master
```

#### High Database Connections
**Symptoms**: Database connection limit reached, application timeouts

**Diagnosis**:
- Check RDS CloudWatch metrics for connection count
- Review application logs for connection pool errors
- Monitor auto-scaling events

**Solutions**:
```hcl
# Increase database connection limit by upgrading instance
db_instance_class = "db.r5.xlarge"

# Optimize connection pooling in n8n
# (handled automatically by the module)
```

#### Auto-Scaling Not Working
**Symptoms**: Services not scaling despite high CPU

**Diagnosis**:
1. Check CloudWatch metrics for CPU utilization
2. Review auto-scaling group history
3. Verify scaling policies are active

**Common Causes**:
- Insufficient ECS cluster capacity
- IAM permissions issues
- Incorrect scaling thresholds

### Performance Optimization

#### Database Performance
```hcl
# Upgrade instance for better performance
db_instance_class = "db.r5.2xlarge"

# Increase allocated storage for better IOPS
db_allocated_storage = 500

# Enable performance insights
db_performance_insights_enabled = true
```

#### Worker Performance
```hcl
# Increase worker resources for complex workflows
worker_fargate_cpu    = 4096
worker_fargate_memory = 8192

# Lower scaling threshold for faster response
autoscaling_worker_cpu_target = 50.0
```

### Monitoring Queries

#### Service Health Check
```bash
# Check all services are running
aws ecs list-services --cluster n8n-production
aws ecs describe-services --cluster n8n-production --services <service-names>
```

#### Database Health
```bash
# Check database status
aws rds describe-db-instances --db-instance-identifier n8n-production

# Monitor recent events
aws rds describe-events --source-identifier n8n-production
```

## Cost Optimization

### Resource Right-Sizing

Monitor actual resource usage and adjust accordingly:

```hcl
# Development environment sizing
master_fargate_cpu    = 1024    # 1 vCPU
master_fargate_memory = 2048    # 2 GB
worker_fargate_cpu    = 1024    # 1 vCPU  
worker_fargate_memory = 2048    # 2 GB
db_instance_class     = "db.t3.medium"
```

### Cost Monitoring

- **AWS Cost Explorer**: Track spending by service and tag
- **CloudWatch Billing**: Set up billing alarms
- **Resource Tagging**: Use consistent tags for cost allocation

### Optimization Strategies

1. **Reserved Instances**: Purchase RDS reserved instances for production
2. **Spot Instances**: Use Spot for development/testing (requires additional configuration)
3. **Automated Scheduling**: Scale down non-production environments after hours
4. **Log Retention**: Adjust CloudWatch log retention based on compliance needs

## Security Best Practices

### Network Security
- Deploy in private subnets only
- Use NAT Gateways for outbound access
- Implement VPC Flow Logs for network monitoring
- Consider AWS WAF for additional protection

### Secrets Management
- Rotate secrets regularly (quarterly minimum)
- Use least privilege IAM policies
- Enable CloudTrail for secrets access auditing
- Consider AWS Systems Manager Parameter Store for non-sensitive configuration

### Compliance
- Enable AWS Config for compliance monitoring  
- Use AWS Security Hub for security posture management
- Implement regular security assessments
- Document security procedures and incident response

## Contributing

We welcome contributions to improve this module:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/improvement`
3. **Make changes**: Follow Terraform best practices
4. **Test thoroughly**: Validate in multiple environments
5. **Submit pull request**: Include detailed description of changes

### Development Guidelines

- **Terraform formatting**: Run `terraform fmt -recursive`
- **Validation**: Run `terraform validate` on all modules
- **Documentation**: Update README for new features
- **Versioning**: Follow semantic versioning

### Testing

```bash
# Format all Terraform files
terraform fmt -recursive

# Validate syntax
terraform validate

# Plan without applying
terraform plan -var-file="terraform.tfvars"
```

## Module Structure

```
terraform-n8n-ecs-module/
├── main.tf                     # Root module - orchestrates all components
├── variables.tf                # Input variable definitions  
├── outputs.tf                  # Output value definitions
├── provider.tf                 # Provider configurations
├── terraform.tfvars.example    # Example configuration file
├── modules/
│   ├── acm/                    # SSL certificate management
│   │   ├── main.tf
│   │   ├── outputs.tf  
│   │   └── variables.tf
│   ├── ecs/                    # ECS services and tasks
│   │   ├── main.tf             # ECS cluster and service definitions
│   │   ├── master.tf           # n8n master service configuration
│   │   ├── worker.tf           # n8n worker service configuration  
│   │   ├── webhook.tf          # n8n webhook service configuration
│   │   ├── alb_master.tf       # Load balancer for master service
│   │   ├── alb_webhook.tf      # Load balancer for webhook service
│   │   ├── alarms.tf           # CloudWatch alarms
│   │   ├── metrics.tf          # CloudWatch metrics
│   │   ├── redis.tf            # Redis service (ECS deployment)
│   │   ├── route53.tf          # DNS record management
│   │   ├── debug_task.tf       # Debug and maintenance tasks
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── networking_existing/    # Integration with existing VPC
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf  
│   ├── networking_create/      # New VPC creation (optional)
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── rds/                    # PostgreSQL database
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── redis/                  # ElastiCache Redis (managed)
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── route53/               # DNS management
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── secrets/               # AWS Secrets Manager integration
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
└── persistency/               # Persistent resources (separate state)
    ├── main.tf                # RDS, ElastiCache, and other stateful resources
    ├── variables.tf           # Persistent resource variables
    └── outputs.tf             # Persistent resource outputs
```

## Support and Community

### Getting Help

- **Issues**: Report bugs or request features via GitHub Issues
- **Discussions**: Join community discussions for best practices
- **Documentation**: Comprehensive docs available in this README
- **Examples**: See `examples/` directory for common configurations

### Related Projects

- **n8n Official Documentation**: [https://docs.n8n.io](https://docs.n8n.io)
- **AWS ECS Best Practices**: [AWS Documentation](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- **Terraform AWS Provider**: [HashiCorp Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

This module represents production-ready infrastructure automation capabilities and enterprise-scale AWS expertise. It's designed to provide a robust, scalable, and secure foundation for running n8n in production environments.

**Built with ❤️ for the n8n and DevOps communities**
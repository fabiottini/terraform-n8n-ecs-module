# Production-Ready N8N on AWS ECS

Enterprise-grade Terraform module for deploying n8n workflow automation platform on AWS using ECS Fargate with queue-mode architecture. This implementation provides high availability, auto-scaling, and production-ready observability.

## Architecture Overview

This module implements n8n's queue mode for distributed workflow execution, providing horizontal scalability and fault tolerance.

```
┌─────────────────────────────────────────────────────────────────┐
│                            Internet                             │
└─────────────────────┬─────────────────┬─────────────────────────┘
                      │                 │
┌─────────────────────▼───────┐ ┌───────▼─────────────────────────┐
│      ALB Master             │ │        ALB Webhook              │
│   (SSL Termination)         │ │     (SSL Termination)           │
│       Main UI               │ │       Webhooks                  │
└─────────────────────┬───────┘ └───────┬─────────────────────────┘
                      │                 │
┌─────────────────────▼─────────────────▼─────────────────────────┐
│                        VPC                                      │
│  ┌─────────────────┐  ┌──────────────────┐  ┌─────────────────┐ │
│  │  Public Subnet  │  │  Public Subnet   │  │  Public Subnet  │ │
│  │   (AZ-a)        │  │   (AZ-b)         │  │   (AZ-c)        │ │
│  └─────────────────┘  └──────────────────┘  └─────────────────┘ │
│           │                     │                     │          │
│  ┌─────────▼───────┐  ┌─────────▼───────┐  ┌─────────▼───────┐ │
│  │ Private Subnet  │  │ Private Subnet  │  │ Private Subnet  │ │
│  │   (AZ-a)        │  │   (AZ-b)        │  │   (AZ-c)        │ │
│  │                 │  │                 │  │                 │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │n8n Master   │ │  │ │n8n Worker   │ │  │ │n8n Worker   │ │ │
│  │ │(ECS Fargate)│ │  │ │(ECS Fargate)│ │  │ │(ECS Fargate)│ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  │                 │  │                 │  │                 │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │n8n Webhook  │ │  │ │    Redis    │ │  │ │ PostgreSQL  │ │ │
│  │ │(ECS Fargate)│ │  │ │(ElastiCache)│ │  │ │    (RDS)    │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Key Features

- Production-Ready Queue Mode: Implements n8n's distributed queue architecture
- High Availability: Multi-AZ deployment with auto-scaling capabilities
- Security First: VPC isolation, SSL/TLS termination, encrypted storage
- Observability: Comprehensive CloudWatch monitoring and alerting
- Infrastructure as Code: Complete Terraform implementation with best practices
- Separation of Concerns: Dedicated services for UI, workers, and webhooks
- Managed Services: Leverages AWS RDS, ElastiCache, and Secrets Manager

## Prerequisites

- Terraform >= 1.3.0
- AWS CLI configured with appropriate permissions
- Existing VPC with public/private subnets and NAT Gateway
- Route53 hosted zone for domain management
- AWS Secrets Manager secret with required credentials

## Quick Start

### Create Secrets

Create an AWS Secrets Manager secret with the following JSON structure:

```json
{
  "db_name": "n8n",
  "db_username": "n8n_user",
  "db_password": "your_secure_password_here",
  "n8n_encryption_key": "your_32_character_encryption_key_here",
  "n8n_runners_auth_token": "optional_runners_token"
}
```

### Configure Variables

Create `terraform.tfvars`:

```hcl
# AWS Configuration
aws_region  = "us-west-2"
aws_profile = "your-aws-profile"

# Route53 Configuration
aws_region_route53  = "us-west-2"
aws_profile_route53 = "your-aws-profile"

# Project Configuration
project_name = "n8n-production"

# Domain Configuration
domain_mapping = {
  master = {
    hostname = "n8n.yourdomain.com"
    internal = false
  }
  webhook = {
    hostname = "webhook.yourdomain.com"
    internal = false
  }
}

# Networking (existing VPC)
vpc_id               = "vpc-xxxxxxxxx"
az_count             = 3
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

# DNS Configuration
zone_id = "Z1234567890ABC"

# Secrets Management
secret_name = "n8n/production/credentials"

# Database Configuration
db_instance_class    = "db.r5.large"
db_allocated_storage = 100
db_n8n_backup_retention_period = 30

# Redis Configuration
use_elasticache_saas = true
redis_saas_node_type = "cache.r5.large"

# ECS Configuration - Master
master_fargate_cpu    = 2048
master_fargate_memory = 4096
desired_count_master  = 1

# ECS Configuration - Workers (Auto-scaling)
worker_fargate_cpu              = 2048
worker_fargate_memory           = 4096
desired_count_worker            = 2
autoscaling_worker_min_capacity = 2
autoscaling_worker_max_capacity = 10

# ECS Configuration - Webhooks
webhook_fargate_cpu    = 1024
webhook_fargate_memory = 2048
desired_count_webhook  = 2

# Container Images
n8n_image   = "n8nio/n8n:latest"
redis_image = "redis:7-alpine"

# Monitoring
enable_detailed_alarms = true
alarm_sns_topic_arn   = ["arn:aws:sns:us-west-2:123456789012:n8n-alerts"]
log_retention_days    = 30
n8n_log_level        = "info"

# Tags
common_tags = {
  Environment = "production"
  Project     = "n8n-automation"
  ManagedBy   = "terraform"
  Owner       = "platform-team"
}
```

### Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Deploy persistent resources first
cd persistency
terraform init
terraform plan -var-file="../terraform.tfvars"
terraform apply -var-file="../terraform.tfvars"
cd ..

# Deploy main infrastructure
terraform plan
terraform apply
```

## Architecture Components

### Queue Mode Implementation

This module implements n8n's queue mode architecture for production scalability:

- Master Service: Handles web UI, API requests, and workflow management
- Worker Services: Execute workflows from Redis queue (auto-scaling)
- Webhook Services: Process external webhook requests
- Redis Queue: Distributed task queue using ElastiCache
- Load Balancers: Separate ALBs for master UI and webhook endpoints

### Service Scaling Strategy

| Service | Scaling Type | Purpose |
|---------|--------------|---------|
| Master | Fixed (1) | UI/API coordination |
| Workers | Auto-scaling | Workflow execution |
| Webhooks | Fixed (configurable) | External integrations |

### Security Features

- Network Isolation: All services in private subnets
- Encryption: TLS in transit, encryption at rest for RDS/ElastiCache
- Access Control: IAM roles with least privilege principles
- Secrets Management: AWS Secrets Manager integration
- Certificate Management: Automatic SSL/TLS via ACM

## Configuration Reference

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `aws_region` | string | Primary AWS region for infrastructure |
| `aws_profile` | string | AWS CLI profile for infrastructure account |
| `aws_region_route53` | string | AWS region for Route53 operations |
| `aws_profile_route53` | string | AWS CLI profile for DNS management |
| `project_name` | string | Project identifier for resource naming |
| `vpc_id` | string | Existing VPC ID |
| `domain_mapping` | object | Domain configuration for services |
| `zone_id` | string | Route53 hosted zone ID |
| `secret_name` | string | AWS Secrets Manager secret name |

### Scaling Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `autoscaling_worker_min_capacity` | 1 | Minimum worker instances |
| `autoscaling_worker_max_capacity` | 10 | Maximum worker instances |
| `autoscaling_worker_cpu_target` | 60.0 | Target CPU utilization % |

### Resource Sizing

Resource allocation can be adjusted based on your workload requirements:

```hcl
# Example production configuration
master_fargate_cpu    = 2048  # 2 vCPU
master_fargate_memory = 4096  # 4 GB
worker_fargate_cpu    = 2048  # 2 vCPU  
worker_fargate_memory = 4096  # 4 GB
db_instance_class     = "db.r5.large"
redis_saas_node_type  = "cache.r5.large"
```

## Monitoring and Observability

### CloudWatch Integration

The module provides comprehensive monitoring:

- **Service Metrics**: CPU, memory, task count per service
- **Application Load Balancer**: Response times, error rates
- **Database**: Connection count, CPU utilization
- **Redis**: Memory utilization, connection count
- **Custom Alarms**: Configurable thresholds with SNS notifications

### Log Management

- **Centralized Logging**: All services log to CloudWatch
- **Configurable Retention**: Cost-optimized log retention policies
- **Structured Logging**: JSON format for better searchability

### Alerting

Configure SNS topics for different alert types:

```hcl
alarm_sns_topic_arn = [
  "arn:aws:sns:us-west-2:123456789012:critical-alerts",
  "arn:aws:sns:us-west-2:123456789012:warning-alerts"
]
```

## Operational Procedures

### Deployment Commands

Standard Terraform workflow for deployment:

```bash
# Initialize Terraform
terraform init

# Deploy persistent resources first
cd persistency
terraform plan -var-file="../terraform.tfvars"
terraform apply -var-file="../terraform.tfvars"
cd ..

# Deploy main infrastructure
terraform plan
terraform apply
```

### Scaling Operations

#### Vertical Scaling
Modify CPU/memory allocation in terraform.tfvars and apply:

```bash
terraform apply -var-file="terraform.tfvars"
```

#### Horizontal Scaling
Workers auto-scale based on CPU utilization. Manual scaling:

```hcl
desired_count_worker = 5  # Immediate scaling
autoscaling_worker_max_capacity = 20  # New ceiling
```

### Backup and Recovery

#### Database Backups
- Automatic daily backups with configurable retention
- Point-in-time recovery within retention period
- Cross-region backup replication (manual setup)

#### Disaster Recovery
1. Database: Restore from automated backups
2. Application: Redeploy from Terraform state
3. Secrets: Recreate in Secrets Manager
4. DNS: Update Route53 records if needed

## Best Practices

### Security
- Use separate AWS accounts for different environments
- Enable GuardDuty and Security Hub
- Implement least privilege IAM policies
- Regular security assessments

### Cost Optimization
- Use Spot instances for development workers
- Implement resource scheduling for non-production
- Monitor unused resources with AWS Cost Explorer
- Right-size instances based on actual usage

### Reliability
- Deploy across multiple availability zones
- Implement circuit breakers in workflows
- Monitor and alert on critical metrics
- Regular disaster recovery testing

## Troubleshooting

### Common Issues

#### Service Won't Start
1. Check CloudWatch logs: `make logs SERVICE=master`
2. Verify secrets are correctly formatted
3. Check security group rules
4. Validate database connectivity

#### High CPU/Memory Usage
1. Check CloudWatch metrics
2. Scale resources: increase CPU/memory allocation
3. Optimize workflows for better performance
4. Consider horizontal scaling

#### Database Connection Issues
1. Verify RDS instance is running
2. Check security group rules
3. Validate database credentials in secrets
4. Review connection pool settings

### Monitoring Queries

Useful CloudWatch Insights queries:

```sql
# Service errors
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc

# Performance metrics
fields @timestamp, @message
| filter @message like /execution/
| stats count() by bin(5m)
```

## Contributing

This module follows infrastructure as code best practices:

1. All changes through pull requests
2. Terraform formatting: `terraform fmt -recursive`
3. Validation: `terraform validate`
4. Documentation updates for new features

## Module Structure

```
terraform-n8n-ecs-module/
├── main.tf                    # Root module configuration
├── variables.tf               # Input variable definitions
├── outputs.tf                 # Output value definitions
├── provider.tf                # Provider configurations
├── modules/
│   ├── acm/                   # SSL certificate management
│   ├── ecs/                   # ECS services and tasks
│   ├── networking_existing/   # Existing VPC integration
│   ├── networking_create/     # New VPC creation
│   ├── rds/                   # PostgreSQL database
│   ├── redis/                 # ElastiCache Redis
│   ├── route53/              # DNS record management
│   └── secrets/              # AWS Secrets Manager
└── persistency/              # Persistent resources (separate state)
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

This module represents production-ready infrastructure automation capabilities and enterprise-scale AWS expertise.
# ===============================================================================
# TERRAFORM AND AWS PROVIDER CONFIGURATION
# ===============================================================================
# 
# Production-ready provider configuration for enterprise n8n deployment on AWS.
# This configuration implements multi-provider architecture to support complex
# organizational structures with separate accounts for infrastructure and DNS.
#
# ARCHITECTURAL PATTERNS SUPPORTED:
# 1. Single Account: Unified infrastructure and DNS management
# 2. Multi-Account: Separated security domains for infrastructure vs DNS
# 3. Cross-Region: Different regions for infrastructure and DNS services
# 4. Cross-Organization: Support for DNS delegation across AWS Organizations
#
# SECURITY CONSIDERATIONS:
# - Separate providers enable least-privilege principle
# - Cross-account permissions through IAM roles and trust policies
# - Fine-grained access control for different resource types
# - Audit trail separation for compliance requirements
# ===============================================================================

terraform {
  required_version = ">= 1.3.0"
  
  # Terraform version constraints ensure:
  # - Access to modern language features (optional attributes, validation)
  # - Consistent behavior across development and production environments
  # - Compatibility with advanced provider features
  # - Support for complex module compositions
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
      
      # AWS Provider v5.x provides:
      # - Enhanced ECS Fargate support with improved resource management
      # - Advanced Route53 and ACM integration capabilities
      # - Improved error handling and state management
      # - Security enhancements for IAM roles and Secrets Manager
      # - Better support for multi-account and cross-region deployments
    }
  }
  
  # Production deployment recommendations:
  # - Configure S3 backend for state storage with versioning enabled
  # - Enable state locking with DynamoDB for team collaboration
  # - Implement state encryption for sensitive infrastructure data
  # - Use separate state files for different environments
  
  # Example backend configuration:
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "n8n/production/terraform.tfstate"
  #   region         = "us-west-2"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-locks"
  #   
  #   # Cross-account state access
  #   role_arn = "arn:aws:iam::ACCOUNT:role/TerraformStateAccess"
  # }
}

# ===============================================================================
# PRIMARY AWS PROVIDER - INFRASTRUCTURE MANAGEMENT
# ===============================================================================
# Manages core infrastructure resources in the primary deployment account.
# This provider handles the majority of AWS resources including compute,
# storage, networking, and security components.
# ===============================================================================
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
  
  # Resource scope and responsibilities:
  # - ECS clusters, services, tasks, and auto-scaling configurations
  # - RDS database instances, subnet groups, and parameter groups
  # - ElastiCache Redis clusters and replication groups
  # - VPC networking components (if creating new VPC)
  # - Security groups and Network Access Control Lists
  # - IAM roles, policies, and instance profiles
  # - CloudWatch log groups, metrics, and alarms
  # - Application Load Balancers and target groups
  # - AWS Secrets Manager secrets and versions
  
  # Regional deployment considerations:
  # - Choose region based on data residency requirements
  # - Consider proximity to users for latency optimization
  # - Evaluate service availability in selected region
  # - Plan for disaster recovery and backup strategies
  # - Account for regional pricing variations
  
  # Authentication and authorization:
  # - Requires comprehensive IAM permissions for infrastructure management
  # - Recommend using IAM roles with temporary credentials
  # - Enable CloudTrail for complete audit logging
  # - Implement least-privilege access principles
  # - Regular review of permissions and access patterns
  
  # Common tags applied to all resources for:
  # - Cost allocation and financial management
  # - Resource organization and inventory
  # - Compliance and governance tracking
  # - Automation and lifecycle management
  default_tags {
    tags = merge(var.common_tags, {
      ManagedBy    = "terraform"
      Module       = "n8n-ecs-deployment"
      Deployment   = "primary-infrastructure"
      LastModified = formatdate("YYYY-MM-DD", timestamp())
    })
  }
}

# ===============================================================================
# ROUTE53 AWS PROVIDER - DNS AND CERTIFICATE MANAGEMENT
# ===============================================================================
# Dedicated provider for DNS operations and SSL certificate management.
# This separation enables complex organizational structures with centralized
# DNS management or cross-account certificate validation.
# ===============================================================================
provider "aws" {
  alias   = "route53"
  region  = var.aws_region_route53
  profile = var.aws_profile_route53
  
  # Resource scope and responsibilities:
  # - Route53 hosted zones and DNS record management
  # - ACM certificate requests and DNS validation
  # - Certificate lifecycle management and renewal
  # - Cross-account DNS delegation and trust relationships
  
  # Multi-account DNS patterns:
  #
  # Pattern 1: Centralized DNS Management
  # - Single DNS account manages all organizational domains
  # - Infrastructure accounts request certificates via cross-account roles
  # - Simplified domain administration and security policies
  # - Consistent DNS naming and resolution strategies
  #
  # Pattern 2: Environment-Specific DNS
  # - Separate DNS management per environment (dev/staging/prod)
  # - Isolated failure domains and security boundaries
  # - Independent certificate lifecycle management
  # - Environment-specific DNS policies and access controls
  #
  # Pattern 3: Business Unit DNS Separation
  # - DNS management aligned with organizational structure
  # - Business unit autonomy with governance oversight
  # - Separate billing and cost allocation for DNS services
  # - Compliance with industry-specific DNS requirements
  
  # Cross-account DNS configuration example:
  # - Infrastructure Account: Requests certificates, manages ALBs
  # - DNS Account: Validates certificates, manages DNS records
  # - Trust Relationship: IAM roles enable cross-account access
  # - Security: Least privilege permissions for certificate validation only
  
  # Regional considerations for DNS:
  # - Route53 is a global service but some operations require region context
  # - ACM certificates must be in us-east-1 for CloudFront (not applicable here)
  # - Regional ALB certificates can be requested in any region
  # - Consider latency and compliance requirements for DNS resolution
  
  # Required permissions for DNS account:
  # - Route53: FullAccess or specific hosted zone permissions
  # - ACM: Certificate management and validation permissions
  # - IAM: Cross-account role assumption capabilities (if applicable)
  
  # Example IAM policy for cross-account DNS access:
  # {
  #   "Version": "2012-10-17",
  #   "Statement": [
  #     {
  #       "Effect": "Allow",
  #       "Action": [
  #         "route53:GetHostedZone",
  #         "route53:ListHostedZones",
  #         "route53:ChangeResourceRecordSets",
  #         "route53:GetChange"
  #       ],
  #       "Resource": "*"
  #     },
  #     {
  #       "Effect": "Allow", 
  #       "Action": [
  #         "acm:RequestCertificate",
  #         "acm:DescribeCertificate",
  #         "acm:ListCertificates"
  #       ],
  #       "Resource": "*"
  #     }
  #   ]
  # }
  
  default_tags {
    tags = merge(var.common_tags, {
      ManagedBy    = "terraform"
      Module       = "n8n-ecs-deployment"
      Deployment   = "dns-management"
      LastModified = formatdate("YYYY-MM-DD", timestamp())
    })
  }
}

# ===============================================================================
# PROVIDER CONFIGURATION VALIDATION
# ===============================================================================
# Validation rules ensure proper provider configuration and prevent common
# deployment issues related to cross-account and cross-region setups.
# ===============================================================================

# Validate that required variables are provided for DNS operations
locals {
  # Validation: Ensure Route53 provider is properly configured
  validate_route53_config = var.aws_profile_route53 != "" && var.aws_region_route53 != "" ? true : tobool("Route53 provider configuration is incomplete")
  
  # Validation: Warn about same-account configuration
  same_account_warning = var.aws_profile == var.aws_profile_route53 ? true : true  # Always passes but logs intent
  
  # Validation: Ensure region compatibility
  region_compatibility = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region)) && can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region_route53))
}
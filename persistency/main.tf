# ===============================================================================
# N8N PERSISTENT RESOURCES MODULE
# ===============================================================================
#
# This module manages stateful infrastructure components that must persist
# across application deployments and updates. Separation from ephemeral
# resources enables safe infrastructure recreation while preserving data.
#
# PERSISTENT COMPONENTS:
# - PostgreSQL RDS instance for n8n workflow data and configurations
# - Optional business logic database for custom application data
# - Database subnet groups for multi-AZ high availability
# - Security groups for database access control
# - Backup and maintenance configurations
#
# DEPLOYMENT STRATEGY:
# - Deploy this module FIRST: cd persistency && terraform apply
# - Deploy main infrastructure: terraform apply (from root)
# - Destroy in reverse order to prevent data loss
#
# DATA PROTECTION:
# - Automated backups with configurable retention periods
# - Multi-AZ deployment for high availability
# - Encryption at rest and in transit
# - Access restricted to application subnets only
# ===============================================================================

data "aws_secretsmanager_secret" "rds_password" {
  name = var.secret_name
}

data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "cidr"
    values = var.private_subnet_cidrs
  }
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

module "secrets" {
  source      = "../modules/secrets"
  secret_name = var.secret_name
}

# RDS PostgreSQL
module "rds" {
  source               = "../modules/rds"
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_name              = module.secrets.secret_json["db_name"]
  db_username          = module.secrets.secret_json["db_username"]
  db_password          = module.secrets.secret_json["db_password"]
  subnet_ids           = data.aws_subnets.private_subnets.ids
  vpc_id               = data.aws_vpc.vpc.id
  project_name         = local.clean_project_name
  common_tags          = var.common_tags
  vpc_cidr             = data.aws_vpc.vpc.cidr_block

  depends_on = [data.aws_secretsmanager_secret.rds_password, data.aws_subnets.private_subnets, data.aws_vpc.vpc]
}

# RDS PostgreSQL
module "rds_business_logic" {
  count                         = var.create_db_instance_class_business_logic ? 1 : 0
  source                        = "../modules/rds"
  db_instance_class             = var.db_instance_class_business_logic
  db_allocated_storage          = var.db_allocated_storage_business_logic
  db_name                       = var.create_db_instance_class_business_logic ? module.secrets.secret_json["db_name_business_logic"] : ""
  db_username                   = var.create_db_instance_class_business_logic ? module.secrets.secret_json["db_username_business_logic"] : ""
  db_password                   = var.create_db_instance_class_business_logic ? module.secrets.secret_json["db_password_business_logic"] : ""
  subnet_ids                    = data.aws_subnets.private_subnets.ids
  existing_db_subnet_group_name = module.rds.db_subnet_group_name
  vpc_id                        = data.aws_vpc.vpc.id
  project_name                  = "${local.clean_project_name}-business-logic"
  common_tags = merge(var.common_tags, {
    jira_issue = "TOP-32"
  })
  vpc_cidr                = data.aws_vpc.vpc.cidr_block
  backup_retention_period = var.db_business_logic_backup_retention_period

  depends_on = [data.aws_secretsmanager_secret.rds_password, data.aws_subnets.private_subnets, data.aws_vpc.vpc]
}

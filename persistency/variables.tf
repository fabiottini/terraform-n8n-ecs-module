variable "aws_region" {
  type        = string
  description = "The AWS region to deploy the resources to"
}

variable "aws_profile" {
  type        = string
  description = "The AWS profile to use for the deployment"
}

variable "db_instance_class" {
  type        = string
  description = "The instance class for the RDS instance"
}

variable "db_allocated_storage" {
  type        = number
  description = "The allocated storage for the RDS instance"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "project_name" {
  type        = string
  description = "The name of the project"
}

variable "common_tags" {
  type        = map(string)
  description = "The common tags to apply to the resources"
}

variable "secret_name" {
  type        = string
  description = "The name of the secret"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "The CIDR blocks for the private subnets"
}

locals {
  clean_project_name = replace(var.project_name, "/[^a-zA-Z0-9]/", "-")
}


variable "db_instance_class_business_logic" {
  type        = string
  description = "The instance class for the RDS instance"
}

variable "db_allocated_storage_business_logic" {
  type        = number
  description = "The allocated storage for the RDS instance"
}

variable "create_db_instance_class_business_logic" {
  type        = string
  description = "Whether to create the RDS instance for the business logic"
}

variable "db_business_logic_backup_retention_period" {
  type        = number
  description = "The backup retention period in days"
}

variable "db_n8n_backup_retention_period" {
  type        = number
  description = "The backup retention period in days"
}
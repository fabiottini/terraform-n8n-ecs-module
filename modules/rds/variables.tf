variable "db_instance_class" {
  description = "RDS instance class/type."
  type        = string
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB."
  type        = number
}

variable "db_name" {
  description = "Database name."
  type        = string
  default     = "n8n"
}

variable "db_username" {
  description = "DB username."
  type        = string
}

variable "db_password" {
  description = "DB password."
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs."
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "project_name" {
  description = "Project name."
  type        = string
}

variable "common_tags" {
  description = "Common tags."
  type        = map(string)
}

variable "vpc_cidr" {
  description = "The CIDR block of the VPC."
  type        = string
}

variable "existing_db_subnet_group_name" {
  description = "Name of an existing DB subnet group to use instead of creating a new one"
  type        = string
  default     = null
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}
variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs."
  type        = list(string)
}

variable "project_name" {
  description = "Project name prefix."
  type        = string
}

variable "common_tags" {
  description = "Common tags."
  type        = map(string)
}

variable "redis_saas_node_type" {
  description = "The type of Redis SaaS to use."
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block of the VPC."
  type        = string
}
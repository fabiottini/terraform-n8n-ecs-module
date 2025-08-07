variable "cname_value" {
  description = "The CNAME value to manage."
  type        = string
}

variable "cname_domain_name" {
  description = "The CNAME domain name to manage."
  type        = list(string)
}

variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "zone_id" {
  description = "The ID of the Route53 zone to manage."
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources."
  type        = map(string)
}

variable "region" {
  description = "The region to manage the Route53 zone."
  type        = string
}
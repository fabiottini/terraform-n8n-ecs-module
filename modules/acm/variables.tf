variable "domains" {
  description = "The domains to create ACM certificates for."
  type        = list(string)
}

variable "zone_id" {
  description = "The ID of the Route53 zone to create the ACM certificates in."
  type        = string
}

variable "common_tags" {
  description = "The common tags to apply to the ACM certificates."
  type        = map(string)
}

variable "project_name" {
  description = "The name of the project."
  type        = string
}
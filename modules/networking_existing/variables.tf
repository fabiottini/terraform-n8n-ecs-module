variable "vpc_id" {
  type        = string
  description = "The ID of the existing VPC"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "The CIDR blocks of the public subnets"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "The CIDR blocks of the private subnets"
}
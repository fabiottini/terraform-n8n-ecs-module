data "aws_vpc" "existing" {
  id = var.vpc_id
}

data "aws_subnets" "all_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "cidr-block"
    values = var.public_subnet_cidrs
  }
}

data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "cidr-block"
    values = var.private_subnet_cidrs
  }
}
output "vpc_id" {
  value = data.aws_vpc.existing.id
}

output "public_subnets" {
  value = data.aws_subnets.public_subnets.ids
}

output "private_subnets" {
  value = data.aws_subnets.private_subnets.ids
}

output "all_subnets" {
  value = data.aws_subnets.all_subnets.ids
}

output "vpc_cidr" {
  value = data.aws_vpc.existing.cidr_block
}
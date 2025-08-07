output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.n8n.id
}

output "public_subnet" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*]
}

output "private_subnet" {
  description = "IDs of the private subnets."
  value       = aws_subnet.private[*]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = [for subnet in aws_subnet.public : subnet.id]
}

# output "alb_security_group_id" {
#   description = "Security group ID for the ALB."
#   value       = aws_security_group.alb.id
# }

# output "ecs_security_group_id" {
#   description = "Security group ID for ECS services."
#   value       = aws_security_group.ecs.id
# }

# output "rds_security_group_id" {
#   description = "Security group ID for RDS."
#   value       = aws_security_group.rds.id
# }

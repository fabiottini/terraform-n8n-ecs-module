output "rds_endpoint" {
  description = "RDS endpoint hostname."
  value       = aws_db_instance.this.endpoint
}

output "rds_port" {
  description = "RDS port."
  value       = aws_db_instance.this.port
}

output "rds_db_name" {
  description = "RDS database name."
  value       = aws_db_instance.this.db_name
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group used (either existing or newly created)"
  value       = local.db_subnet_group_name
}

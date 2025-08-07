# Data source to check if DB subnet group already exists
data "aws_db_subnet_group" "existing" {
  count = var.existing_db_subnet_group_name != null ? 1 : 0
  name  = var.existing_db_subnet_group_name
}

# Local values to determine which DB subnet group to use
locals {
  db_subnet_group_name = var.existing_db_subnet_group_name != null ? var.existing_db_subnet_group_name : aws_db_subnet_group.this[0].name
}

resource "aws_db_subnet_group" "this" {
  count      = var.existing_db_subnet_group_name == null ? 1 : 0
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = merge(var.common_tags, { Name = "${var.project_name}-db-subnet-group" })
}

resource "aws_db_instance" "this" {
  identifier              = "${var.project_name}-db"
  engine                  = "postgres"
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = local.db_subnet_group_name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  skip_final_snapshot     = true
  publicly_accessible     = false
  multi_az                = true
  storage_encrypted       = true
  backup_retention_period = var.backup_retention_period
  tags                    = merge(var.common_tags, { Name = "${var.project_name}-db" })

  # only for migration purposes
  # Legacy configuration maintained for compatibility
  # lifecycle {
  #   ignore_changes = [
  #     db_name,
  #     username,
  #     password
  #   ]
  # }
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for n8n RDS ${var.project_name}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-rds-sg" })
}



resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "aws_db_subnet_group" "main" {
  name       = "konecta-erp-db-${var.environment}"
  subnet_ids = var.private_subnet_ids
  tags = {
    Name = "konecta-erp-db-subnet-${var.environment}"
  }
}

resource "aws_security_group" "rds" {
  name        = "konecta-erp-rds-${var.environment}"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "konecta-erp-rds-sg-${var.environment}"
  }
}

data "aws_vpc" "main" {
  id = var.vpc_id
}

resource "aws_db_instance" "postgres" {
  identifier             = "konecta-erp-${var.environment}"
  engine                 = "postgres"
  engine_version         = "15.8"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  max_allocated_storage  = var.db_allocated_storage * 2
  db_name                = "konecta_erp"
  username               = "postgres"
  password               = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  backup_retention_period = 7
  storage_encrypted      = true
  iam_database_authentication_enabled = true
  tags = {
    Name = "konecta-erp-db-${var.environment}"
  }
}

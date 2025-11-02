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
    cidr_blocks = concat([data.aws_vpc.main.cidr_block], var.additional_allowed_cidrs)
  }
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.eks_security_group_ids
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

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name               = "konecta-erp-rds-em-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "monitoring.rds.amazonaws.com" },
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name = "konecta-erp-rds-em-${var.environment}"
  }
}

resource "aws_iam_role_policy_attachment" "rds_em_attach" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Primary RDS instance
resource "aws_db_instance" "postgres" {
  count = var.create_replica ? 0 : 1
  
  identifier             = "konecta-erp-${var.environment}"
  engine                 = var.db_engine
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
  storage_encrypted      = var.storage_encrypted
  iam_database_authentication_enabled = true
  copy_tags_to_snapshot  = true
  deletion_protection    = var.deletion_protection
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  monitoring_interval    = var.enable_enhanced_monitoring ? var.monitoring_interval : 0
  monitoring_role_arn    = var.enable_enhanced_monitoring ? aws_iam_role.rds_enhanced_monitoring.arn : null
  performance_insights_enabled          = var.enable_performance_insights
  performance_insights_retention_period = var.enable_performance_insights ? var.pi_retention_period : null
  tags = {
    Name = "konecta-erp-db-${var.environment}"
  }
}

# KMS key for DR region
resource "aws_kms_key" "dr" {
  count = var.create_replica ? 1 : 0
  description = "KMS key for RDS replica encryption"
  tags = {
    Name = "konecta-erp-${var.environment}-dr-key"
  }
}

# DR subnet group
resource "aws_db_subnet_group" "secondar-rds-subentg" {
  count = var.create_replica ? 1 : 0
  name = "konecta-erp-db-${var.environment}-dr"
  subnet_ids = var.private_subnet_ids
  tags = {
    Name = "konecta-erp-db-subnet-${var.environment}-dr"
  }
}

# DR security group
resource "aws_security_group" "db_dr" {
  count = var.create_replica ? 1 : 0
  name = "konecta-erp-rds-${var.environment}-dr"
  vpc_id = var.vpc_id
  
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "konecta-erp-rds-sg-${var.environment}-dr"
  }
}

# Cross-region read replica
resource "aws_db_instance" "replica" {
  count = var.create_replica ? 1 : 0
  
  identifier = "konecta-erp-${var.environment}-replica"
  replicate_source_db = var.source_db_identifier
  instance_class = var.replica_instance_class
  
  publicly_accessible = false
  storage_encrypted = true
  kms_key_id = aws_kms_key.dr[0].arn
  db_subnet_group_name = aws_db_subnet_group.secondar-rds-subentg[0].name
  vpc_security_group_ids = [aws_security_group.db_dr[0].id]
  
  backup_retention_period = var.replica_backup_retention
  deletion_protection = var.replica_deletion_protection
  
  monitoring_interval = var.enable_enhanced_monitoring ? var.monitoring_interval : 0
  monitoring_role_arn = var.enable_enhanced_monitoring ? aws_iam_role.rds_enhanced_monitoring.arn : null
  performance_insights_enabled = var.enable_performance_insights
  
  tags = {
    Name = "konecta-erp-${var.environment}-replica"
    Type = "ReadReplica"
    Purpose = "DisasterRecovery"
  }
}
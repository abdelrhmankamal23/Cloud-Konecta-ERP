terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Deploy DR infrastructure in eu-west-1 (safe from us-east-1 failures)
provider "aws" {
  region = "eu-west-1"
}

# Provider to monitor primary region resources
provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

# Data sources
data "aws_caller_identity" "current" {}

# ECR Cross-Region Replication
resource "aws_ecr_replication_configuration" "dr_replication" {
  replication_configuration {
    rule {
      destination {
        region      = var.secondary_region
        registry_id = data.aws_caller_identity.current.account_id
      }
      
      repository_filter {
        filter      = "${var.project_name}/*"
        filter_type = "PREFIX_MATCH"
      }
    }
  }
}

# S3 Bucket for DR Configuration Storage
resource "aws_s3_bucket" "dr_configs" {
  bucket = "konecta-erp-dr-configs"
  
  tags = merge(var.common_tags, {
    Name = "DR Configuration Storage"
  })
}

resource "aws_s3_bucket_versioning" "dr_configs" {
  bucket = aws_s3_bucket.dr_configs.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Lambda Function for DR Automation
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/dr_failover.zip"
  source_dir  = "${path.module}/lambda"
}

# IAM Role for Lambda DR Function
resource "aws_iam_role" "lambda_dr" {
  name = "${var.project_name}-lambda-dr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_dr" {
  name = "${var.project_name}-lambda-dr-policy"
  role = aws_iam_role.lambda_dr.id
  policy = file("${path.module}/policies/lambda-dr-policy.json")
}

resource "aws_lambda_function" "dr_failover" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-dr-failover"
  role            = aws_iam_role.lambda_dr.arn
  handler         = "dr_failover.handler"
  runtime         = "python3.9"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  
  environment {
    variables = {
      DR_REGION        = var.secondary_region
      PRIMARY_REGION   = var.primary_region
      RDS_REPLICA_ID   = var.rds_replica_id
      EKS_CLUSTER_NAME = var.eks_cluster_name_dr
      APP_NAMESPACE    = var.app_namespace
      APP_SERVICE_NAME = var.app_service_name
      DR_CONFIG_BUCKET = "konecta-erp-dr-configs"
    }
  }
  
  depends_on = [aws_iam_role_policy.lambda_dr]
  
  tags = var.common_tags
}

# Lambda Permission for CloudWatch Alarms
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dr_failover.function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:${var.primary_region}:${data.aws_caller_identity.current.account_id}:alarm:*"
}

# CloudWatch Alarm for RDS Failure Detection - Monitor us-east-1 from eu-west-1
resource "aws_cloudwatch_metric_alarm" "rds_primary_failure" {
  provider = aws.primary 
  
  alarm_name          = "${var.project_name}-rds-primary-failure"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Primary RDS instance failure detection - Auto DR trigger"
  alarm_actions       = [
    aws_sns_topic.dr_alerts.arn,
    aws_lambda_function.dr_failover.arn
  ]
  treat_missing_data  = "breaching"
  
  dimensions = {
    DBInstanceIdentifier = var.rds_primary_id
  }
  
  tags = merge(var.common_tags, {
    Name = "RDS Primary Failure Alarm - Auto DR"
  })
}

# Find ALB created by Kubernetes AWS Load Balancer Controller
data "aws_lb" "kubernetes_alb" {
  provider = aws.primary
  
  tags = {
    "kubernetes.io/cluster/konecta-erp-dev" = "owned"
  }
}

# ALB Target Health Alarm - Monitor us-east-1 from eu-west-1
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_targets" {
  provider = aws.primary  # Monitor primary region from DR region
  
  alarm_name          = "${var.project_name}-alb-unhealthy-targets"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 10
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "ALB has no healthy targets - Auto DR trigger"
  alarm_actions = compact([
    aws_sns_topic.dr_alerts.arn,
    aws_lambda_function.dr_failover.arn
  ])
  treat_missing_data = "breaching"
  
  dimensions = {
    LoadBalancer = data.aws_lb.kubernetes_alb.arn_suffix
  }
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = merge(var.common_tags, {
    Name = "ALB Unhealthy Targets - Auto DR"
  })
}


resource "aws_sns_topic" "dr_alerts" {
  name = "${var.project_name}-dr-alerts"
  
  tags = merge(var.common_tags, {
    Name = "DR Alerts Topic"
  })
}


resource "aws_sns_topic_subscription" "email_alerts" {
  count = length(var.notification_email)
  topic_arn = aws_sns_topic.dr_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email[count.index]
}
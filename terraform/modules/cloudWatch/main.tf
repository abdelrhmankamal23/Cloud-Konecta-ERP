# terraform/modules/cloudwatch/main.tf

resource "aws_cloudwatch_dashboard" "rds" {
  dashboard_name = "konecta-erp-rds-${var.environment}"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x = 0, y = 0, width = 12, height = 6,
        properties = {
          title = "CPU Utilization",
          metrics = [["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_identifier]],
          period = 60,
          stat = "Average",
          region = var.aws_region,
          view = "timeSeries"
        }
      },
      {
        type = "metric",
        x = 12, y = 0, width = 12, height = 6,
        properties = {
          title = "Database Connections",
          metrics = [["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.db_identifier]],
          period = 60,
          stat = "Average",
          region = var.aws_region,
          view = "timeSeries"
        }
      },
      {
        type = "metric",
        x = 0, y = 6, width = 12, height = 6,
        properties = {
          title = "Free Storage Space",
          metrics = [["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.db_identifier]],
          period = 60,
          stat = "Minimum",
          region = var.aws_region,
          view = "timeSeries"
        }
      },
      {
        type = "metric",
        x = 12, y = 6, width = 12, height = 6,
        properties = {
          title = "Read/Write Latency (ms)",
          metrics = [
            ["AWS/RDS", "ReadLatency", "DBInstanceIdentifier", var.db_identifier, { "stat": "Average" }],
            ["AWS/RDS", "WriteLatency", "DBInstanceIdentifier", var.db_identifier, { "stat": "Average" }]
          ],
          period = 60,
          region = var.aws_region,
          view = "timeSeries"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "konecta-erp-rds-cpu-high-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU > 80% for 5 minutes"
  alarm_actions       = var.rds_alarm_actions
  dimensions = {
    DBInstanceIdentifier = var.db_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  alarm_name          = "konecta-erp-rds-free-storage-low-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 5
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Minimum"
  threshold           = 2147483648
  alarm_description   = "RDS free storage < 2GB for 5 minutes"
  alarm_actions       = var.rds_alarm_actions
  dimensions = {
    DBInstanceIdentifier = var.db_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_db_connections_high" {
  alarm_name          = "konecta-erp-rds-connections-high-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 100
  alarm_description   = "RDS database connections unusually high"
  alarm_actions       = var.rds_alarm_actions
  dimensions = {
    DBInstanceIdentifier = var.db_identifier
  }
}

# EKS Fargate-only: Alarms using Container Insights pod metrics aggregated cluster-wide
resource "aws_cloudwatch_metric_alarm" "eks_pod_cpu_high" {
  alarm_name          = "${var.project_name}-eks-pod-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 80
  alarm_description   = "EKS average pod CPU utilization > 80%"
  alarm_actions       = var.eks_alarm_actions

  metric_query {
    id          = "m1"
    return_data = false
    metric {
      namespace   = "ContainerInsights"
      metric_name = "pod_cpu_utilization"
      dimensions = {
        ClusterName = var.eks_cluster_name
        Namespace   = "*"
      }
      period = 300
      stat   = "Average"
    }
  }

  metric_query {
    id          = "e1"
    expression  = "AVG(METRICS())"
    label       = "Avg Pod CPU Utilization"
    return_data = true
  }
}

resource "aws_cloudwatch_metric_alarm" "eks_pod_memory_high" {
  alarm_name          = "${var.project_name}-eks-pod-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 80
  alarm_description   = "EKS average pod memory utilization > 80%"
  alarm_actions       = var.eks_alarm_actions

  metric_query {
    id          = "m1"
    return_data = false
    metric {
      namespace   = "ContainerInsights"
      metric_name = "pod_memory_utilization"
      dimensions = {
        ClusterName = var.eks_cluster_name
        Namespace   = "*"
      }
      period = 300
      stat   = "Average"
    }
  }

  metric_query {
    id          = "e1"
    expression  = "AVG(METRICS())"
    label       = "Avg Pod Memory Utilization"
    return_data = true
  }
}

# Optional: Log group for EKS logs
resource "aws_cloudwatch_log_group" "eks_logs" {
  name              = "/aws/eks/${var.eks_cluster_name}/cluster"
  retention_in_days = 14
}
resource "aws_cloudwatch_dashboard" "eks_dashboard" {
  dashboard_name = "${var.project_name}-eks-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x    = 0,
        y    = 0,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ { "expression": "AVG(SEARCH('{ContainerInsights,ClusterName,Namespace} MetricName=\"pod_cpu_utilization\" ClusterName=\"${var.eks_cluster_name}\"', 'Average', 300))", "label": "Avg Pod CPU", "id": "e1" } ]
          ],
          title = "EKS Pod CPU Utilization (Avg)",
          period = 300,
          stat = "Average"
        }
      },
      {
        type = "metric",
        x    = 0,
        y    = 6,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ { "expression": "AVG(SEARCH('{ContainerInsights,ClusterName,Namespace} MetricName=\"pod_memory_utilization\" ClusterName=\"${var.eks_cluster_name}\"', 'Average', 300))", "label": "Avg Pod Memory", "id": "e2" } ]
          ],
          title = "EKS Pod Memory Utilization (Avg)",
          period = 300,
          stat = "Average"
        }
      }
    ]
  })
}

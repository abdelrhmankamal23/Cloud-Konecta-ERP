# terraform/modules/cloudwatch/main.tf

# Optional: SNS topic for notifications
resource "aws_sns_topic" "alert_topic" {
  name = "${var.project_name}-eks-alert-topic"
}

# EKS CPU Utilization alarm
resource "aws_cloudwatch_metric_alarm" "eks_cpu_high" {
  alarm_name          = "${var.project_name}-eks-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EKS node CPU utilization is too high"
  dimensions = {
    ClusterName = var.eks_cluster_name
    NodeName    = var.node_group_name
  }
  alarm_actions = [aws_sns_topic.alert_topic.arn]
}

# EKS Memory Utilization alarm
resource "aws_cloudwatch_metric_alarm" "eks_memory_high" {
  alarm_name          = "${var.project_name}-eks-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_memory_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EKS node memory utilization is too high"
  dimensions = {
    ClusterName = var.eks_cluster_name
    NodeName    = var.node_group_name
  }
  alarm_actions = [aws_sns_topic.alert_topic.arn]
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
            [ "ContainerInsights", "node_cpu_utilization", "ClusterName", var.eks_cluster_name, "NodeName", var.node_group_name ]
          ],
          title = "EKS Node CPU Utilization",
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
            [ "ContainerInsights", "node_memory_utilization", "ClusterName", var.eks_cluster_name, "NodeName", var.node_group_name ]
          ],
          title = "EKS Node Memory Utilization",
          period = 300,
          stat = "Average"
        }
      }
    ]
  })
}

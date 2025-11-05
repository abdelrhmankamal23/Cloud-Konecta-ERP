variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for metrics visualization"
  type        = string
}

variable "db_identifier" {
  description = "RDS DBInstanceIdentifier to monitor"
  type        = string
}

variable "rds_alarm_actions" {
  description = "List of ARNs to notify when RDS alarms fire (e.g., SNS topic ARNs)"
  type        = list(string)
  default     = []
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "konecta-erp"
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "eks_alarm_actions" {
  description = "List of ARNs to notify when EKS alarms fire (SNS topic ARNs)"
  type        = list(string)
  default     = []
}

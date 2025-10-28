output "sns_topic_arn" {
  description = "SNS topic ARN for EKS CloudWatch alerts"
  value       = aws_sns_topic.alert_topic.arn
}

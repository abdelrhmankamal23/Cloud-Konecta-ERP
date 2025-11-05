
output "dr_config_bucket_name" {
  description = "DR configuration S3 bucket name"
  value       = aws_s3_bucket.dr_configs.bucket
}

output "dr_lambda_function_name" {
  description = "DR Lambda function name"
  value       = aws_lambda_function.dr_failover.function_name
}

output "dr_lambda_function_arn" {
  description = "DR Lambda function ARN"
  value       = aws_lambda_function.dr_failover.arn
}

output "sns_topic_arn" {
  description = "SNS topic ARN for DR alerts"
  value       = aws_sns_topic.dr_alerts.arn
}

output "cloudwatch_alarm_name" {
  description = "CloudWatch alarm name for RDS failure"
  value       = aws_cloudwatch_metric_alarm.rds_primary_failure.alarm_name
}

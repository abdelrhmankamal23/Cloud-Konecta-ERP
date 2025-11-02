output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = length(aws_db_instance.postgres) > 0 ? aws_db_instance.postgres[0].endpoint : null
}

output "db_password" {
  description = "Database password"
  value       = random_password.db_password.result
  sensitive   = true
}

output "db_name" {
  description = "Database name"
  value       = length(aws_db_instance.postgres) > 0 ? aws_db_instance.postgres[0].db_name : null
}

output "db_username" {
  description = "Database username"
  value       = length(aws_db_instance.postgres) > 0 ? aws_db_instance.postgres[0].username : null
}

output "db_arn" {
  description = "RDS instance ARN"
  value       = length(aws_db_instance.postgres) > 0 ? aws_db_instance.postgres[0].arn : null
}

output "db_identifier" {
  description = "RDS instance identifier"
  value       = length(aws_db_instance.postgres) > 0 ? aws_db_instance.postgres[0].id : null
}

output "replica_endpoint" {
  description = "RDS replica endpoint"
  value       = length(aws_db_instance.replica) > 0 ? aws_db_instance.replica[0].endpoint : null
}

output "replica_identifier" {
  description = "RDS replica identifier"
  value       = length(aws_db_instance.replica) > 0 ? aws_db_instance.replica[0].id : null
}
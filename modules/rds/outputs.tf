output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "db_password" {
  description = "Database password"
  value       = random_password.db_password.result
  sensitive   = true
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.postgres.db_name
}

output "db_username" {
  description = "Database username"
  value       = aws_db_instance.postgres.username
}

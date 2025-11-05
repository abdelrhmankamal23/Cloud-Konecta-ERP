output "db_secret_arn" {
  description = "ARN of the database password secret"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "jwt_secret_arn" {
  description = "ARN of the JWT secret"
  value       = aws_secretsmanager_secret.jwt_secret.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key for secrets encryption"
  value       = aws_kms_key.secrets_key.arn
}

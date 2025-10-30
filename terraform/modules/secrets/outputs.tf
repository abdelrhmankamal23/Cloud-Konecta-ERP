output "db_secret_arn" {
  description = "ARN of the database password secret"
  value       = var.existing_db_secret_name != "" ? data.aws_secretsmanager_secret.existing_db[0].arn : aws_secretsmanager_secret.db_password[0].arn
}

output "jwt_secret_arn" {
  description = "ARN of the JWT secret"
  value       = var.existing_jwt_secret_name != "" ? data.aws_secretsmanager_secret.existing_jwt[0].arn : aws_secretsmanager_secret.jwt_secret[0].arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key for secrets encryption"
  value       = var.existing_kms_key_arn != "" ? var.existing_kms_key_arn : aws_kms_key.secrets_key[0].arn
}

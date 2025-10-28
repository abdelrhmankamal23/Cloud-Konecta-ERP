resource "aws_secretsmanager_secret" "db_password" {
  name                    = "konecta-erp-db-password-${var.environment}"
  recovery_window_in_days = 0
  kms_key_id              = aws_kms_key.secrets_key.arn
  tags = {
    Name = "konecta-erp-db-password-${var.environment}"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = "postgres"
    password = var.db_password
  })
}

resource "aws_kms_key" "secrets_key" {
  description             = "KMS key for Konecta ERP secrets encryption"
  deletion_window_in_days = 7
  tags = {
    Name = "konecta-erp-secrets-key-${var.environment}"
  }
}

resource "aws_kms_alias" "secrets_key_alias" {
  name          = "alias/konecta-erp-secrets-${var.environment}"
  target_key_id = aws_kms_key.secrets_key.key_id
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name                    = "konecta-erp-jwt-secret-${var.environment}"
  recovery_window_in_days = 0
  kms_key_id              = aws_kms_key.secrets_key.arn
  tags = {
    Name = "konecta-erp-jwt-secret-${var.environment}"
  }
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = jsonencode({
    secret = "i0eCF0g/9rj5xLQOpPT2xWHDyKtqzjnE220yTdrjJwI8/w1NtH7xB9/T8MqqHaAn"
  })
}

data "aws_secretsmanager_secret" "existing_db" {
  count = var.existing_db_secret_name != "" ? 1 : 0
  name  = var.existing_db_secret_name
}

data "aws_secretsmanager_secret" "existing_jwt" {
  count = var.existing_jwt_secret_name != "" ? 1 : 0
  name  = var.existing_jwt_secret_name
}

resource "aws_kms_key" "secrets_key" {
  count                  = var.existing_kms_key_arn == "" ? 1 : 0
  description            = "KMS key for Konecta ERP secrets encryption"
  deletion_window_in_days = 7
  tags = {
    Name = "konecta-erp-secrets-key-${var.environment}"
  }
}

resource "aws_kms_alias" "secrets_key_alias" {
  count        = var.existing_kms_key_arn == "" ? 1 : 0
  name         = "alias/konecta-erp-secrets-${var.environment}"
  target_key_id = aws_kms_key.secrets_key[0].key_id
}

locals {
  kms_key_arn = var.existing_kms_key_arn != "" ? var.existing_kms_key_arn : aws_kms_key.secrets_key[0].arn
}

resource "aws_secretsmanager_secret" "db_password" {
  count                   = var.existing_db_secret_name == "" ? 1 : 0
  name                    = "konecta-erp-db-password-${var.environment}"
  recovery_window_in_days = 0
  kms_key_id              = local.kms_key_arn
  tags = {
    Name = "konecta-erp-db-password-${var.environment}"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  count        = var.existing_db_secret_name == "" ? 1 : 0
  secret_id    = aws_secretsmanager_secret.db_password[0].id
  secret_string = jsonencode({
    username = "postgres"
    password = var.db_password
  })
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  count                   = var.existing_jwt_secret_name == "" ? 1 : 0
  name                    = "konecta-erp-jwt-secret-${var.environment}"
  recovery_window_in_days = 0
  kms_key_id              = local.kms_key_arn
  tags = {
    Name = "konecta-erp-jwt-secret-${var.environment}"
  }
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  count         = var.existing_jwt_secret_name == "" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.jwt_secret[0].id
  secret_string = jsonencode({
    secret = "i0eCF0g/9rj5xLQOpPT2xWHDyKtqzjnE220yTdrjJwI8/w1NtH7xB9/T8MqqHaAn"
  })
}

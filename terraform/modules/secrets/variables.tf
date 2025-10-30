variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "db_password" {
  description = "Database password to store in secrets manager"
  type        = string
  sensitive   = true
}

variable "existing_db_secret_name" {
  description = "If set, use an existing Secrets Manager secret for DB credentials"
  type        = string
  default     = ""
}

variable "existing_jwt_secret_name" {
  description = "If set, use an existing Secrets Manager secret for JWT"
  type        = string
  default     = ""
}

variable "existing_kms_key_arn" {
  description = "If set, use an existing KMS key for secrets encryption"
  type        = string
  default     = ""
}

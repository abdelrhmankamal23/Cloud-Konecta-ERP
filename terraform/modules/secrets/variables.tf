variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "db_password" {
  description = "Database password to store in secrets manager"
  type        = string
  sensitive   = true
}

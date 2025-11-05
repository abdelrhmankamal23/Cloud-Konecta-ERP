# Disaster Recovery Variables

# Kubernetes Configuration
variable "app_namespace" {
  description = "Kubernetes namespace where the app is deployed"
  type        = string
  default     = "default"
}

variable "app_service_name" {
  description = "Kubernetes service name for the app"
  type        = string
  default     = "konecta-erp-service"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "konecta-erp"
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "dr_region" {
  description = "Disaster recovery AWS region"
  type        = string
  default     = "eu-west-1"
}

# RDS Configuration
variable "rds_replica_id" {
  description = "RDS replica identifier (must exist in DR region)"
  type        = string
  default     = "konecta-erp-dev-replica"
  
  validation {
    condition     = length(var.rds_replica_id) > 0
    error_message = "RDS replica ID cannot be empty."
  }
}

variable "rds_primary_id" {
  description = "RDS primary identifier"
  type        = string
  default     = "konecta-erp-dev"
}

# EKS Configuration
variable "eks_cluster_name_dr" {
  description = "EKS cluster name in DR region"
  type        = string
  default     = "konecta-erp-dev-dr"
}

variable "alarm_evaluation_periods" {
  description = "CloudWatch alarm evaluation periods"
  type        = number
  default     = 3
}

variable "alarm_period" {
  description = "CloudWatch alarm period in seconds"
  type        = number
  default     = 300
}

variable "notification_email" {
  description = "Email addresses for DR notifications"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "Konecta-ERP"
    Environment = "dev"
    Owner   = "Terraform"
    Purpose     = "DisasterRecovery"
  }
}
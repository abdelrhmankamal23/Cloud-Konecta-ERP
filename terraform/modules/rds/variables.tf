variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where RDS will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for RDS"
  type        = list(string)
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "deletion_protection" {
  description = "Enable deletion protection on the primary RDS instance"
  type        = bool
  default     = true
}

variable "storage_encrypted" {
  description = "Enable storage encryption for RDS"
  type        = bool
  default     = true
}

variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "postgres"
}

variable "additional_allowed_cidrs" {
  description = "Additional CIDR blocks allowed to access RDS (e.g., peer VPCs in other regions)"
  type        = list(string)
  default     = []
}

variable "enable_enhanced_monitoring" {
  description = "Enable RDS Enhanced Monitoring"
  type        = bool
  default     = true
}

variable "monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds (1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 60
}

variable "enable_performance_insights" {
  description = "Enable RDS Performance Insights"
  type        = bool
  default     = true
}

variable "pi_retention_period" {
  description = "Performance Insights retention period in days (7 or 731)"
  type        = number
  default     = 7
}

variable "eks_security_group_ids" {
  description = "List of EKS security group IDs that need access to RDS"
  type        = list(string)
  default     = []
}

# Replica variables
variable "create_replica" {
  description = "Whether to create a cross-region read replica"
  type        = bool
  default     = false
}

variable "source_db_identifier" {
  description = "Source database ARN for cross-region replica"
  type        = string
  default     = ""
}

variable "replica_instance_class" {
  description = "Instance class for the read replica"
  type        = string
  default     = "db.t3.micro"
}

variable "replica_backup_retention" {
  description = "Backup retention period for replica"
  type        = number
  default     = 7
}

variable "replica_deletion_protection" {
  description = "Enable deletion protection on replica"
  type        = bool
  default     = true
}
# Global variables used across regions
variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "enable_vpc_peering" {
  description = "Enable VPC peering"
  type        = bool
  default     = false
}

variable "peer_vpc_id" {
  description = "Peer VPC ID for peering"
  type        = string
  default     = ""
}

variable "peer_cidr_block" {
  description = "Peer VPC CIDR block"
  type        = string
  default     = ""
}

variable "peer_region" {
  description = "Peer VPC region"
  type        = string
  default     = ""
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage"
  type        = number
  default     = 20
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "replica_instance_class" {
  description = "RDS replica instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "replica_deletion_protection" {
  description = "Enable deletion protection for replica"
  type        = bool
  default     = true
}

variable "bastion_host_key_name" {
  description = "Key pair name for bastion host"
  type        = string
  default     = ""
}

variable "team_admin_arns" {
  description = "List of team admin ARNs"
  type        = list(string)
  default     = []
}

variable "ssl_certificate_arn" {
  description = "SSL certificate ARN"
  type        = string
  default     = ""
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
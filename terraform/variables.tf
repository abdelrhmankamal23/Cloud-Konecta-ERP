variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "deployment_type" {
  description = "Deployment type: always 'full' but controls which components are enabled"
  type        = string
  default     = "full"
}

variable "enable_rds" {
  description = "Enable RDS database"
  type        = bool
  default     = true
}

variable "enable_eks" {
  description = "Enable EKS cluster"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "enable_vpc_peering" {
  description = "Enable VPC peering to a secondary VPC"
  type        = bool
  default     = false
}

variable "peer_vpc_id" {
  description = "Peer VPC ID (secondary region)"
  type        = string
  default     = ""
}

variable "peer_cidr_block" {
  description = "Peer VPC CIDR block"
  type        = string
  default     = ""
}

variable "peer_region" {
  description = "Peer VPC region (required for cross-region peering)"
  type        = string
  default     = ""
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

variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS listener (optional)"
  type        = string
  default     = ""
}

variable "bastion_host_key_name" {
  description = "Name of the EC2 Key Pair to use for bastion host"
  type        = string
  default     = ""
}

variable "team_admin_arns" {
  description = "List of IAM user/role ARNs for EKS cluster admin access"
  type        = list(string)
  default     = []
}

variable "rds_alarm_actions" {
  description = "List of ARNs to notify when RDS alarms fire (e.g., SNS topic ARNs)"
  type        = list(string)
  default     = []
}

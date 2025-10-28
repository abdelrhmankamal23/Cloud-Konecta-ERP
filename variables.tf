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
  description = "Map of availability zones"
  type        = map(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
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

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS listener (optional)"
  type        = string
  default     = ""
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access EKS API server publicly"
  type        = list(string)
  default = [
    "0.0.0.0/0"
  ]
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
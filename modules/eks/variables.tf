variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EKS will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS nodes"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for EKS control plane"
  type        = list(string)
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

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access EKS API server publicly"
  type        = list(string)
  default     = [
    "0.0.0.0/0"
  ]
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "team_admin_arns" {
  description = "List of IAM role/user ARNs for the EKS admin team"
  type        = list(string)
}
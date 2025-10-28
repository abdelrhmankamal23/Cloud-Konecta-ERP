variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "node_role_name" {
  description = "Name of the EKS node IAM role for ECR access"
  type        = string
}


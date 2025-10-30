variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EKS will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for Fargate pods"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for EKS control plane"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "team_admin_arns" {
  description = "List of IAM role/user ARNs for the EKS admin team"
  type        = list(string)
}

variable "ssl_certificate_arn" {
  description = "ACM certificate ARN for HTTPS on the ALB listener"
  type        = string
  default     = ""
}

variable "enable_cloudwatch_observability_addon" {
  description = "Enable the amazon-cloudwatch-observability EKS add-on via Terraform"
  type        = bool
  default     = false
}

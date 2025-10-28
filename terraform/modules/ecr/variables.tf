


variable "fargate_pod_execution_role_name" {
  description = "Name of the Fargate Pod Execution Role for ECR access"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
}

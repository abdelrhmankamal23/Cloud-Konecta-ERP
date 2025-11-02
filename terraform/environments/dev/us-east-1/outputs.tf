# Deployment outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "ecr_repositories" {
  description = "Map of ECR repository URLs"
  value       = module.ecr.ecr_repositories
}

# Output its ARN for DR
output "primary_db_arn" {
  value = module.rds.db_arn
}

output "primary_rds_endpoint" {
  description = "RDS database endpoint"
  value       = module.rds.db_endpoint
}

output "primary_rds_password" {
  description = "RDS database password"
  value       = module.rds.db_password
  sensitive   = true
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

# Added: expose fargate profile and pod execution role for downstream consumers
output "eks_fargate_profile_name" {
  description = "Fargate profile name for the EKS cluster (if available)"
  value       = try(module.eks.fargate_profile_name, null)
}

output "eks_fargate_pod_execution_role_name" {
  description = "IAM role name used by Fargate pods (if available)"
  value       = try(module.eks.fargate_pod_execution_role_name, null)
}

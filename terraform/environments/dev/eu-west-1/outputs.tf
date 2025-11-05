# DR Region Outputs
output "dr_vpc_id" {
  description = "DR VPC ID"
  value       = module.vpc.vpc_id
}

output "dr_eks_cluster_name" {
  description = "DR EKS cluster name"
  value       = module.eks.cluster_name
}

output "dr_eks_cluster_endpoint" {
  description = "DR EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "dr_rds_endpoint" {
  description = "DR RDS endpoint"
  value       = module.rds.db_endpoint
}

output "dr_ecr_repositories" {
  description = "DR ECR repository URLs"
  value       = module.ecr.ecr_repositories
}
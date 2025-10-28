# Deployment outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.eks.alb_dns_name
}

output "ecr_repositories" {
  description = "Map of ECR repository URLs"
  value       = module.ecr.ecr_repositories
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain name (HTTPS endpoint)"
  value       = local.is_prod ? module.cloudfront[0].cloudfront_domain : null
}

output "db_endpoint" {
  description = "RDS database endpoint"
  value       = terraform.workspace == "prod" ? module.rds[0].db_endpoint : null
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

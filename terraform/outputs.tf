output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.eks.alb_dns_name
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront.cloudfront_domain
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for frontend"
  value       = module.s3.bucket_name
}

output "db_endpoint" {
  description = "RDS database endpoint"
  value       = module.rds.db_endpoint
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "ecr_repositories" {
  description = "Map of ECR repository URLs"
  value       = module.eks.ecr_repositories
}

output "db_secret_arn" {
  description = "ARN of the database password secret"
  value       = module.secrets.db_secret_arn
}

output "jwt_secret_arn" {
  description = "ARN of the JWT secret"
  value       = module.secrets.jwt_secret_arn
}

output "eks_nodes_security_group_id" {
  description = "Security group ID for EKS nodes"
  value       = module.eks.eks_nodes_security_group_id
}

output "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  value       = module.eks.alb_target_group_arn
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = module.vpc.bastion_public_ip
}

output "bastion_private_ip" {
  description = "Private IP address of the bastion host"
  value       = module.vpc.bastion_private_ip
}

output "eks_cluster_ca_certificate" {
  description = "Base64 encoded certificate data for EKS cluster"
  value       = module.eks.cluster_ca_certificate
}
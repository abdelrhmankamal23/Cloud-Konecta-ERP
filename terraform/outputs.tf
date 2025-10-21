# Common outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket for frontend"
  value       = module.s3.bucket_name
}

# Deployment outputs
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
  value       = terraform.workspace == "prod" ? module.cloudfront[0].cloudfront_domain : null
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
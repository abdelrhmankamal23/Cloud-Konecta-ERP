output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_ca_certificate" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "fargate_profile_name" {
  description = "Name of the Fargate profile"
  value       = aws_eks_fargate_profile.main.fargate_profile_name
}

output "fargate_pod_execution_role_name" {
  description = "Name of the IAM role for Fargate pods"
  value       = aws_iam_role.fargate.name
}

# output "alb_dns_name" {
#   description = "ALB DNS will be created by AWS Load Balancer Controller via Ingress"
#   value       = "managed-by-ingress-controller"
# }

# output "load_balancer_controller_role_arn" {
#   description = "ARN of the Load Balancer Controller IAM role"
#   value       = aws_iam_role.aws_load_balancer_controller.arn
# }

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

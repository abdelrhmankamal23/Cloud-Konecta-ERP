output "ecr_repositories" {
  description = "Map of ECR repository URLs"
  value       = { for k, v in aws_ecr_repository.services : k => v.repository_url }
}

output "ecr_repository_arns" {
  description = "Map of ECR repository ARNs"
  value       = { for k, v in aws_ecr_repository.services : k => v.arn }
}

output "ecr_repository_names" {
  description = "Map of ECR repository names"
  value       = { for k, v in aws_ecr_repository.services : k => v.name }
}


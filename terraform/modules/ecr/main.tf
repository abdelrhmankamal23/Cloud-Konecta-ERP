# ECR Repository for Docker Images
resource "aws_ecr_repository" "services" {
  for_each = toset([
   # "konecta-auth-service",
   # "konecta-gateway-service",
   # "konecta-discovery-server",
   # "konecta-config-server",
   # "konecta-hr-service",
   # "konecta-finance-service",
   # "konecta-inventory-service",
   # "konecta-reporting-service",
   # "konecta-frontend"
  ])
  
  name                 = "konecta-erp/${each.key}"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  encryption_configuration {
    encryption_type = "AES256"
  }
  
  tags = {
    Name        = "konecta-erp-${each.key}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Lifecycle Policy for ECR repositories
resource "aws_ecr_lifecycle_policy" "services" {
  for_each = aws_ecr_repository.services
  
  repository = each.value.name
  
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# IAM Policy for Fargate Pod Execution Role to access ECR
resource "aws_iam_role_policy" "ecr_access" {
  name = "konecta-erp-ecr-access-${var.environment}"
  role = var.fargate_pod_execution_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:ListImages"
        ]
        Resource = "*"
      }
    ]
  })
}

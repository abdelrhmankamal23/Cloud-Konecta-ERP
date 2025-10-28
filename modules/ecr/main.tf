# ECR Repository for Docker Images
resource "aws_ecr_repository" "services" {
  for_each = toset(["auth-service", "hr-service", "finance-service", "operation-service", "gateway-service", "discovery-server", "config-server", "reporting-service"])
  
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
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# IAM Policy for EKS Node Group to access ECR
resource "aws_iam_role_policy" "ecr_access" {
  name = "konecta-erp-ecr-access-${var.environment}"
  role = var.node_role_name

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


###############################################
# EKS Cluster
###############################################
resource "aws_eks_cluster" "main" {
  name     = "konecta-erp-${var.environment}"
  role_arn = aws_iam_role.cluster.arn
  version  = "1.29"

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = {
    Name = "konecta-erp-cluster-${var.environment}"
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}

###############################################
# IAM Role for Cluster
###############################################
resource "aws_iam_role" "cluster" {
  name = "konecta-erp-cluster-role-${var.environment}"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.cluster.name
}

###############################################
# IAM Role for Fargate Pods
###############################################
resource "aws_iam_role" "fargate" {
  name = "konecta-erp-fargate-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "fargate_execution_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate.name
}

###############################################
# Fargate Profile
###############################################
resource "aws_eks_fargate_profile" "main" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "konecta-erp-fargate-${var.environment}"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = var.private_subnet_ids

   selector {
    namespace = "*"
  }
  tags = {
    Name = "konecta-erp-fargate-${var.environment}"
  }

  depends_on = [
    aws_iam_role_policy_attachment.fargate_execution_policy
  ]
}

###############################################
# Give Each Team Member Full Cluster Admin Access
###############################################
resource "aws_eks_access_entry" "team_admins" {
  for_each       = toset(var.team_admin_arns)
  cluster_name   = aws_eks_cluster.main.name
  principal_arn  = each.key
  type           = "STANDARD"
}

resource "aws_eks_access_policy_association" "team_admins_policy" {
  for_each      = toset(var.team_admin_arns)
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.key

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

###############################################
# Application Load Balancer (unchanged)
###############################################
resource "aws_security_group" "alb" {
  name   = "konecta-erp-alb-${var.environment}"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "konecta-erp-alb-sg-${var.environment}"
  }
}

resource "aws_lb" "main" {
  name               = "konecta-erp-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "konecta-erp-alb-${var.environment}"
  }
}

resource "aws_lb_target_group" "main" {
  name     = "konecta-erp-tg-${var.environment}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "konecta-erp-tg-${var.environment}"
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = {
    Name = "konecta-erp-listener-${var.environment}"
  }
}

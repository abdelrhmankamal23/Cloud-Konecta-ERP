###############################################
# EKS Cluster
###############################################
resource "aws_eks_cluster" "main" {
  name     = "konecta-erp-${var.environment}"
  role_arn = aws_iam_role.cluster.arn
  version  = "1.32"

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

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
# IRSA: OIDC Provider for Service Accounts
###############################################
data "tls_certificate" "oidc" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
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

resource "aws_iam_role_policy_attachment" "fargate_cloudwatch_agent" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.fargate.name
}

###############################################
# IRSA Role for CloudWatch Agent (Observability add-on)
###############################################
# resource "aws_iam_role" "cloudwatch_agent_irsa" {
#   name = "konecta-erp-cwagent-irsa-${var.environment}"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Federated = aws_iam_openid_connect_provider.cluster.arn
#         },
#         Action = "sts:AssumeRoleWithWebIdentity",
#         Condition = {
#           StringEquals = {
#             "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:aud" : "sts.amazonaws.com",
#             "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub" : "system:serviceaccount:aws-observability:cloudwatch-agent"
#           }
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "cloudwatch_agent_irsa_attach" {
#   role       = aws_iam_role.cloudwatch_agent_irsa.name
#   policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
# }

###############################################
# EKS Add-on: CloudWatch Observability
###############################################
# resource "aws_eks_addon" "cloudwatch_observability" {
#   cluster_name                = aws_eks_cluster.main.name
#   addon_name                  = "amazon-cloudwatch-observability"
#   resolve_conflicts_on_create = "OVERWRITE"
#   resolve_conflicts_on_update = "OVERWRITE"
#   service_account_role_arn    = aws_iam_role.cloudwatch_agent_irsa.arn

#   depends_on = [
#     aws_iam_openid_connect_provider.cluster,
#     aws_iam_role_policy_attachment.cloudwatch_agent_irsa_attach
#   ]
# }

# ###############################################
# # EKS Node Group (for Load Balancer Controller)
# ###############################################
# resource "aws_iam_role" "node_group" {
#   name = "konecta-erp-nodegroup-role-${var.environment}"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Service = "ec2.amazonaws.com"
#       }
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "node_group_AmazonEKSWorkerNodePolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.node_group.name
# }

# resource "aws_iam_role_policy_attachment" "node_group_AmazonEKS_CNI_Policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.node_group.name
# }

# resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2ContainerRegistryReadOnly" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.node_group.name
# }

# resource "aws_eks_node_group" "main" {
#   cluster_name    = aws_eks_cluster.main.name
#   node_group_name = "konecta-erp-nodegroup-${var.environment}"
#   node_role_arn   = aws_iam_role.node_group.arn
#   subnet_ids      = var.private_subnet_ids
#   instance_types  = ["t3.medium"]

#   scaling_config {
#     desired_size = 2
#     max_size     = 3
#     min_size     = 1
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy,
#     aws_iam_role_policy_attachment.node_group_AmazonEKS_CNI_Policy,
#     aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryReadOnly,
#   ]

#   tags = {
#     Name = "konecta-erp-nodegroup-${var.environment}"
#   }
# }

###############################################
# Fargate Profile (for application pods)
###############################################
resource "aws_eks_fargate_profile" "main" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "konecta-erp-fargate-${var.environment}"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = var.private_subnet_ids

  selector {
    namespace = "*"
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
# EKS Add-on: CloudWatch Observability
###############################################

resource "aws_iam_role" "cloudwatch_agent_irsa" {
  name = "konecta-erp-cwagent-irsa-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.cluster.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:aud" : "sts.amazonaws.com",
            "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub" : "system:serviceaccount:aws-observability:cloudwatch-agent"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_irsa_attach" {
  role       = aws_iam_role.cloudwatch_agent_irsa.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "amazon-cloudwatch-observability"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = aws_iam_role.cloudwatch_agent_irsa.arn

  depends_on = [
    aws_iam_openid_connect_provider.cluster,
    aws_iam_role_policy_attachment.cloudwatch_agent_irsa_attach
  ]
}




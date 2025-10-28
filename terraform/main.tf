terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Owner   = "Terraform"
      Project = "Konecta_ERP"
      Env     = terraform.workspace
    }
  }
}

locals {
  environment = terraform.workspace
  is_prod     = terraform.workspace == "prod"
}

module "vpc" {
  source = "./modules/vpc"
  
  environment           = local.environment
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  enable_nat_gateway    = var.enable_nat_gateway
  bastion_host_key_name = var.bastion_host_key_name
}

module "rds" {
  count  = local.is_prod ? 1 : 0
  source = "./modules/rds"
  
  environment          = local.environment
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
}

module "secrets" {
  count  = local.is_prod ? 1 : 0
  source = "./modules/secrets"
  
  environment = local.environment
  db_password = module.rds[0].db_password
}

module "eks" {
  source = "./modules/eks"
  
  environment        = local.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  vpc_cidr           = module.vpc.vpc_cidr_block
  team_admin_arns    = var.team_admin_arns
}

module "ecr" {
  source = "./modules/ecr"
  
  environment = local.environment

  # With Fargate there is no node IAM role; pass the Fargate pod execution role name
  # (module.eks must export fargate_pod_execution_role_name in the eks module outputs)
  fargate_pod_execution_role_name = try(module.eks.fargate_pod_execution_role_name, null)
}

module "cloudfront" {
  count  = local.is_prod ? 1 : 0
  source = "./modules/cloudfront"
  
  environment           = local.environment
  alb_domain            = module.eks.alb_dns_name
  cloudfront_log_bucket = ""
  waf_web_acl_id        = ""
}

module "cloudwatch" {
  source           = "./modules/cloudwatch"
  project_name     = "konecta-erp"
  eks_cluster_name = module.eks.cluster_name

  # Node group name removed because cluster is now Fargate-based.
  # If cloudwatch module requires this, update that module to accept a null/optional value
  # or to monitor Fargate metrics instead.
}

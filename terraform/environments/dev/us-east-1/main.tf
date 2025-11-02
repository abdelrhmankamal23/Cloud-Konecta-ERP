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
      Env     = local.environment
      Region  = "Primary"
    }
  }
}

locals {
  environment = terraform.workspace
}

module "vpc" {
  source = "../../../modules/vpc"
  
  environment           = local.environment
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  enable_nat_gateway    = var.enable_nat_gateway
  enable_vpc_peering    = var.enable_vpc_peering
  peer_vpc_id           = var.peer_vpc_id
  peer_cidr_block       = var.peer_cidr_block
  peer_region           = var.peer_region
}

module "eks" {
  source = "../../../modules/eks"
  
  environment        = local.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  vpc_cidr           = module.vpc.vpc_cidr_block
  team_admin_arns    = var.team_admin_arns
  ssl_certificate_arn = var.ssl_certificate_arn
}

module "ecr" {
  source = "../../../modules/ecr"
  environment                      = local.environment
  fargate_pod_execution_role_name  = module.eks.fargate_pod_execution_role_name
}


module "rds" {
  source = "../../../modules/rds"
  environment             = local.environment
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  db_instance_class       = var.db_instance_class
  db_allocated_storage    = var.db_allocated_storage
  deletion_protection     = var.deletion_protection
  storage_encrypted       = var.storage_encrypted
  db_engine               = var.db_engine
  
  
  eks_security_group_ids  = [module.eks.cluster_security_group_id]
  
  # Replica settings (not created in primary)
  create_replica = false
}

module "secrets" {
  source      = "../../../modules/secrets"
  environment = local.environment
  db_password = module.rds.db_password
}

module "cloudwatch" {
  source = "../../../modules/cloudwatch"

  environment       = local.environment
  aws_region        = var.aws_region
  db_identifier     = module.rds.db_identifier
  rds_alarm_actions = var.rds_alarm_actions
  project_name      = "konecta-erp"
  eks_cluster_name  = module.eks.cluster_name
  eks_alarm_actions = var.rds_alarm_actions
}
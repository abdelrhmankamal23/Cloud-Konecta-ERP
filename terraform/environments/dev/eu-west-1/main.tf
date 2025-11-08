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
      Env     = var.environment
      Region  = "DR"
    }
  }
}

locals {
  environment = terraform.workspace
}

module "vpc" {
  source = "../../../modules/vpc"
  
  environment           = "${local.environment}-dr"
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  enable_nat_gateway    = var.enable_nat_gateway
  enable_vpc_peering    = false
}

data "terraform_remote_state" "primary" {
  backend = "s3"
  config = {
    bucket = "konecta-erp-terraform-state-primary"
    key    = "dev/us-east-1/terraform.tfstate"
    region = "us-east-1"
  }
}

# EKS and ECR will be created by Lambda during DR failover
# Keeping only essential standby infrastructure

# RDS Read Replica for DR
module "rds" {
  source = "../../../modules/rds"
  
  environment             = "${local.environment}-dr"
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  
  db_instance_class       = var.replica_instance_class
  db_allocated_storage    = 20
  deletion_protection     = var.replica_deletion_protection
  storage_encrypted       = var.storage_encrypted
  db_engine              = var.db_engine
  
  # Replica configuration
  create_replica          = true
  source_db_identifier    = data.terraform_remote_state.primary.outputs.primary_db_arn
  replica_deletion_protection = var.replica_deletion_protection
  
  # No EKS security groups for minimal standby
}

# Secrets for DR region
module "secrets" {
  source      = "../../../modules/secrets"
  environment = "${local.environment}-dr"
  db_password = module.rds.db_password
}
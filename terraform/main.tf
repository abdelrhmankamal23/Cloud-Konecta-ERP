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
    }
  }
}

module "vpc" {
  source             = "./modules/vpc"
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  enable_nat_gateway = var.enable_nat_gateway
  # bastion_host_key_name = var.bastion_host_key_name
}

# module "rds" {
#   source               = "./modules/rds"
#   environment          = var.environment
#   vpc_id               = module.vpc.vpc_id
#   private_subnet_ids   = module.vpc.private_subnet_ids
#   db_instance_class    = var.db_instance_class
#   db_allocated_storage = var.db_allocated_storage
# }

# module "secrets" {
#   source      = "./modules/secrets"
#   environment = var.environment
#   db_password = module.rds.db_password
# }

module "eks" {
  source             = "./modules/eks"
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  node_instance_type = var.node_instance_type
  node_desired_size  = var.node_desired_size
  node_max_size      = var.node_max_size
  node_min_size      = var.node_min_size
  key_name           = var.key_name
  vpc_cidr           = module.vpc.vpc_cidr_block
}

# module "s3" {
#   source                     = "./modules/s3"
#   environment                = var.environment
#   bucket_name                = "konecta-erp-frontend-${var.environment}-${random_id.bucket_suffix.hex}"
#   cloudfront_distribution_id = module.cloudfront.cloudfront_distribution_id
# }

# module "cloudfront" {
#   source           = "./modules/cloudfront"
#   environment      = var.environment
#   s3_bucket_domain = module.s3.bucket_domain_name
#   alb_domain       = module.eks.alb_dns_name
# }

resource "random_id" "bucket_suffix" {
  byte_length = 4
}
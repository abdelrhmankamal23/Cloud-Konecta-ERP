# Terraform and Provider Versions

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# Primary region provider
provider "aws" {
  region = var.primary_region
  
  default_tags {
    tags = var.common_tags
  }
}

# DR region provider
provider "aws" {
  alias  = "dr"
  region = var.dr_region
  
  default_tags {
    tags = merge(var.common_tags, {
      Region = "DR"
    })
  }
}
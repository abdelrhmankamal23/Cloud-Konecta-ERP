terraform {
  backend "s3" {
    bucket               = "konecta-erp-terraform-state-us-east"
    key                  = "konecta-erp/terraform.tfstate"
    workspace_key_prefix = "env"
    region               = "us-east-1"
    encrypt              = true
    use_lockfile         = true
  }
}
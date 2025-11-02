terraform {
  backend "s3" {
    bucket         = "konecta-erp-terraform-state-us-east"
    key            = "dev/us-east-1/terraform.tfstate"
    region         = "us-east-1"
    workspace_key_prefix = "env"
    encrypt        = true
    use_lockfile = true
  }
}
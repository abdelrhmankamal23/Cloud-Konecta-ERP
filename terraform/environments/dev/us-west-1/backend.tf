terraform {
  backend "s3" {
    bucket         = "konecta-erp-terraform-state-secondary"
    key            = "dev/us-west-1/terraform.tfstate"
    region         = "us-west-1"
    workspace_key_prefix = "env"
    encrypt        = true
    use_lockfile = true
  }
}

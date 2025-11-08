terraform {
  backend "s3" {
    bucket         = "konecta-erp-terraform-state-secondary"
    key            = "dev/eu-west-1-dr-active/terraform.tfstate"
    region         = "eu-west-1"
    workspace_key_prefix = "env"
    encrypt        = true
    use_lockfile = true
  }
}

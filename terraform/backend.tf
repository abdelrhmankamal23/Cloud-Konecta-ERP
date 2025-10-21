terraform {
  backend "s3" {
    bucket = "konecta-erp-terraform-state"
    key    = "terraform.tfstate"
    workspace_key_prefix = "env"
    region = "eu-west-1"
    encrypt = true
    use_lockfile = true
  }
}

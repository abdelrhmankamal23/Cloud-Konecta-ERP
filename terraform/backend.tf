terraform {
  backend "s3" {
    bucket  = "konecta-erp-terraform-state"
    key     = "konecta-erp/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    use_lockfile = true
  }
}

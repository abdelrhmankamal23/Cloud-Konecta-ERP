terraform {
  backend "s3" {
    # Replace with your actual S3 bucket name
    bucket  = "konecta-erp-terraform-state"
    key     = "konecta-erp/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    # Optional: DynamoDB table for state locking (create manually if needed)
    # dynamodb_table = "your-terraform-locks-table"
  }
}

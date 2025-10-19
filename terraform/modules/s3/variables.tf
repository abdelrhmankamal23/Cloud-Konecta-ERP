variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket for frontend hosting"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  type        = string
}

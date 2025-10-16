variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "s3_bucket_domain" {
  description = "S3 bucket domain name for CloudFront origin"
  type        = string
}

variable "alb_domain" {
  description = "Application Load Balancer domain name"
  type        = string
}

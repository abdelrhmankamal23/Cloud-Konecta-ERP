variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "alb_domain" {
  description = "Application Load Balancer domain name"
  type        = string
}

variable "cloudfront_log_bucket" {
  description = "S3 bucket for CloudFront access logs"
  type        = string
  default     = ""
}

variable "waf_web_acl_id" {
  description = "WAF Web ACL ID for CloudFront security (optional)"
  type        = string
  default     = ""
}


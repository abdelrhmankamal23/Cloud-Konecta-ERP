resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  default_root_object = "index.html"
  comment             = "CloudFront distribution for Konecta ERP - ${var.environment}"
  
  origin {
    domain_name = var.alb_domain
    origin_id   = "ALB-EKS"
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2", "TLSv1.3"]
      origin_read_timeout   = 60
      origin_keepalive_timeout = 5
    }

    custom_header {
      name  = "X-Forwarded-Proto"
      value = "https"
    }
  }

  default_cache_behavior {
    target_origin_id       = "ALB-EKS"
    viewer_protocol_policy = "redirect-to-https"
    
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD"]
    
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Managed-CachingOptimizedForCompression
    
    compress = true
    
    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
    
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b554e877" # Managed-SecurityHeadersPolicy
  }

  # WAF Web ACL for security (optional but recommended)
  web_acl_id = var.waf_web_acl_id
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true # Uses CloudFront SSL
    minimum_protocol_version       = "TLSv1.2_2021"
  }
  
  dynamic "logging_config" {
    for_each = var.cloudfront_log_bucket != "" ? [1] : []
    content {
      bucket         = var.cloudfront_log_bucket
      include_cookies = false
      prefix         = "cloudfront-logs"
    }
  }

  # Custom error responses
  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/index.html"
  }
  
  custom_error_response {
    error_code         = 403
    response_code      = 403
    response_page_path = "/index.html"
  }

  tags = {
    Name        = "konecta-erp-cdn-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
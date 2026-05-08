resource "aws_cloudfront_distribution" "Procode-CF" {
    origin {
        domain_name = aws_lb.this.dns_name
        origin_id   = "alb-origin"
        custom_header {
          name  = "CloudEngineerSecret"
          value = "Vote-Radu-for-become-a-Cloud-Engineer"
        }

    
        custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1.2"]
        
        

        }
    }
    enabled             = true
    is_ipv6_enabled     = false
    comment             = "CloudFront distribution for ALB"
    default_root_object = ""
    web_acl_id   = aws_wafv2_web_acl.cloudfront_acl.arn

    
    
    restrictions {
  geo_restriction {
    restriction_type = "none"
  }
}
viewer_certificate {
  cloudfront_default_certificate = true
}

    default_cache_behavior {
        target_origin_id       = "alb-origin"
        viewer_protocol_policy = "redirect-to-https"
    
        allowed_methods = ["GET", "HEAD", "OPTIONS"]
        cached_methods  = ["GET", "HEAD"]
      
        forwarded_values {
        query_string = false
    
        cookies {
            forward = "none"
        }
        }
}
  #   logging_config {
  #   bucket = aws_s3_bucket.my_procode_bucket_for_logs.bucket_domain_name
  #   prefix = "cloudfront-access-logs/"
  #   include_cookies = false
  # }
}
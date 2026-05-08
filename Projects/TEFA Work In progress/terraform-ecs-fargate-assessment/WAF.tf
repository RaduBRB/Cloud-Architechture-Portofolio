resource "aws_wafv2_ip_set" "allowed_ips" {
    name               = "allowed-public-ips"
    description        = "Allowed IPs for CloudFront access"
    scope              = "CLOUDFRONT"
    ip_address_version = "IPV4"
    addresses = var.allowed_ipv4_cloudfront
}

resource "aws_wafv2_web_acl" "cloudfront_acl" {
    name        = "cloudfront-ip-restriction"
    scope       = "CLOUDFRONT"

    default_action {
        block {}
    }

rule {
    name     = "AllowCloudFrontIPs"
    priority = 1

    statement {
        ip_set_reference_statement {
            arn = aws_wafv2_ip_set.allowed_ips.arn
        }
    }

    action {
        allow {}
    }

    visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name              = "allow-cloudfront-ips"
        sampled_requests_enabled = true
    }
}

visibility_config {
  cloudwatch_metrics_enabled = true
  metric_name              = "cloudfront-ip-restriction"
  sampled_requests_enabled = true
    } 
}

#This resource configures logging for the WAF ACL, sending logs to a Kinesis Firehose delivery stream.
# resource "aws_wafv2_web_acl_logging_configuration" "cloudfront_waf_logging" {
#   resource_arn = aws_wafv2_web_acl.cloudfront_acl.arn
#   provider = aws.us_east_1

#   log_destination_configs = [
#     aws_kinesis_firehose_delivery_stream.waf_logs_stream.arn
#   ]
#   depends_on = [ aws_kinesis_firehose_delivery_stream.waf_logs_stream ]
# }


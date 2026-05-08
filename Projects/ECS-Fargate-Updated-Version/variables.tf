variable "region"{
    description = "The region where the service will be deployed"
    type = string
    default = "us-east-1"
}

variable "vpc_cidr"{
    description = "CIDR block for the VPC"
    type = string
    default = "10.0.0.0/16"
  
}

variable "allowed_ip"{
    description = "Public IP allowed to access the load balancer"
    default = "0.0.0.0/0"
    type = string
  
}

variable "allowed_ipv4_cloudfront" {
    description = "Public IP allowed to access the load balancer through CloudFront"
    type = list(string)
  
}


variable "allowed_ipv6_cloudfront" {
  description = "Allowed IPv6 addresses for CloudFront access"
  type        = list(string)
}


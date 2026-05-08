#Prints the VPC ID after deploymnet 
output "vpc_id" {
    value = aws_vpc.main.id
}

#Prints the IDss of the public subnets
output "public_subnets" {
    value = [
        aws_subnet.public_subnet_1.id,
        aws_subnet.public_subnet_2.id
    ]
}

#Print the application URL (For internal use only) This can be opened only by adding the secret header value. 
output "application_url" {
    value = "http://${aws_lb.this.dns_name}"
}                              

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}


#Public endpoint served by CloudFront
output "cloudfront_url" {
  description = "Public HTTPS endpoint served by CloudFront"
  value       = "https://${aws_cloudfront_distribution.Procode-CF.domain_name}"
}

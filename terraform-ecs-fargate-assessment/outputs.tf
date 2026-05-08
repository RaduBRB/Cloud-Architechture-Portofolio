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

#Prints the public URL of the application and allows to click the link after deployment for testing
output "application_url" {
    value = "http://${aws_lb.this.dns_name}"
}                              
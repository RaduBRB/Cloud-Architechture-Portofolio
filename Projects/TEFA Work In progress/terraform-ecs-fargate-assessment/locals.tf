locals {
  public_subnets = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

#CIDR blocks for public subnets
  public_subnet_cidrs = [
    aws_subnet.public_subnet_1.cidr_block,
    aws_subnet.public_subnet_2.cidr_block
  ]
}

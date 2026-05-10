variable "region" {
    default = "us-east-1"
    description = "The region location"
}

variable "account_id" {
    default = "362649471889"
    description = "The AWS account ID"
  
}

variable "vpc_cidr" {}
variable "azs" {}
variable "public_subnets" {}
variable "private_subnets" {}

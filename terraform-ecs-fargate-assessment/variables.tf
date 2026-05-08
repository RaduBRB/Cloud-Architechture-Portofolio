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
    type = string
  
}


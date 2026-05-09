variable "public_subnets" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)    
}

variable "vpc_id" {
  description = "VPC Id"
  type = string
}


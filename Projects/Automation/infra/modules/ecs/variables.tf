variable "vpc_id" {
    type = string
  
}

variable "subnets" {
    type = list(string)
  
}
variable "alb_sg_id" {
    type = string
  
}

variable "target_group_arn" {
    type = string
  
}
variable "listener_arn" {
    type = string
  
}

variable "image_url" {
    type = string
  
}


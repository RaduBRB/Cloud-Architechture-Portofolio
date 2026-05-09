provider "aws" {
    region = var.region
}

module "ecr" {
  source = "../../modules/ecr"

  repo_name = "procode-ecr-repository"
}
module "alb" {
  source = "../../modules/alb"

  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
}

module "ecs" {
  source = "../../modules/ecs"

  vpc_id = module.vpc.vpc_id

  subnets = module.vpc.public_subnets

  alb_sg_id        = module.alb.alb_security_group_id
  target_group_arn = module.alb.target_group_arn
  listener_arn     = module.alb.listener_arn

  image_url = "991150654740.dkr.ecr.us-east-1.amazonaws.com/procode-ecr-repository:latest"
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr = "10.0.0.0/16"

  azs = ["us-east-1a", "us-east-1b"]

  public_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  private_subnets = [
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]
}
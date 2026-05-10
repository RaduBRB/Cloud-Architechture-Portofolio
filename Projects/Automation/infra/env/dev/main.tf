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

  image_url = "${var.account_id}.dkr.ecr.us-east-1.amazonaws.com/procode-ecr-repository:latest"
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr = var.vpc_cidr

  azs = var.azs

  public_subnets = var.public_subnets

  private_subnets = var.private_subnets
}

module "iam" {
  source = "../../modules/iam"

}
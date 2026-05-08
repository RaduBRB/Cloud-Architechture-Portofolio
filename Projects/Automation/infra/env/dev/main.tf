provider "aws" {
    region = var.region
}

resource "aws_ecr_repository" "Procode_ECR_Repository" {
    name = "procode-ecr-repository"
    image_tag_mutability = "IMMUTABLE"
    image_scanning_configuration {
      scan_on_push = true
    }
  
}


provider "aws"{
    region = "us-east-1"
    alias = "us_east_1"
}

#This is the backend for the TF state however the S3 bucket has to be created manually before otherwise the backend initialization will fail.
#In Terraform the backend is initialized before Terraform can manage any resources.
terraform {
  backend "s3" {
    bucket = "my-procode-bucket-for-backend"
    key    = "procode/my-ecs/terraform.tfstate"
    region = "us-east-1"
  }
}

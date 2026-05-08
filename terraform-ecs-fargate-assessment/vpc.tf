#Creates a Virtual Private Cloud
resource "aws_vpc" "main"{
    cidr_block = var.vpc_cidr #Defines the IP Range for the entire network
    enable_dns_support = true #Allowws AWS to resolve DNS names inside the VPC
    enable_dns_hostnames = true #Allows ALB DNS names, ECS tasks to pull images and allows getting public DNS Names

    tags = {
      Name = "procode_vpc"
    }

}

#Creates a gateway for the public subnets to be able to reach out the internet, allows the ALB to be publicly accesible and allows the ECS tasks to pull images from ECR
resource "aws_internet_gateway" "igw"{
    vpc_id = aws_vpc.main.id
    tags = {
      Name = "procode_igw"
    }
}

#First public subnet created in the AZ us-east-1a, while allowing any EC2/ECS tasks launched to get an public IP atutomatically. The CIDR Block allows 256 Ip addresses 
resource "aws_subnet" "public_subnet_1" {
  vpc_id = aws_vpc.main.id 
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_1"
  }

}
#Second public subnet created in the AZ us-east-1b, while allowing any EC2/ECS tasks launched to get an public IP atutomatically. The CIDR Block allows 256 Ip addresses
resource "aws_subnet" "public_subnet_2" {
  vpc_id = aws_vpc.main.id
  cidr_block =  "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_2"
  }
}

#Create a route table for the public subnets.If a subnet has a route to an IGW, it becomes public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

#Connects subnet one to the public route table which gives it acccess to internet
resource "aws_route_table_association" "public_1" {
  subnet_id = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public.id

}

#Connects subnet one to the public route table which gives it acccess to internet
resource "aws_route_table_association" "public_2" {
  subnet_id = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public.id
}
#The Security group controls the traffic to and from the ALB
resource "aws_security_group" "alb_sg" {
    name = "alb-sg"
    vpc_id = aws_vpc.main.id
#Ingress traffic is the incoming traffic. In this instance it allows HTTP transfer on port 80 only from the allowed IP addresses. In this case /32 means one IP address.
#It prevents anyone else on the internet from accessing the ALB, which would be a security concern otherwise. 
ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.allowed_ip}/32"]
  }

# Egress is the outbound traffic and in this instance allows all the outbound traffic which is required by the ALB to perform health checks and communicate with the Containers/Tasks
egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}
}

resource "aws_security_group" "ecs_sg" {
  name   = "ecs-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = local.public_subnet_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


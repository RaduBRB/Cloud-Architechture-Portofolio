resource "aws_ecs_cluster" "this" {
  name = "procode-ecs-cluster"
}

# Security Group for ECS
resource "aws_security_group" "ecs_sg" {
  name = "procode-ecs-sg"
  description = "allow traffic from alb"
  vpc_id = var.vpc_id
    ingress {
        from_port = 3000
        to_port = 3000 
        protocol = "tcp"
        security_groups = [var.alb_sg_id] #Only alb can access
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
# Task Definition
resource "aws_ecs_task_definition" "this" {
    family = "procode-task"
    requires_compatibilities = ["FARGATE"]
    network_mode = "awsvpc"
    cpu = "256"
    memory = "512"
    execution_role_arn = aws_iam_role.ecs_execution.arn
    container_definitions = jsonencode([
        { 
            name = "procode-container"
            image = var.image_url  
            essential = true
            portMappings = [
                {
                    containerPort = 3000
                    hostPort = 3000
                    protocol = "tcp"
                }
            ] 
        } 
    ])   
}


# ECS Service (THIS connects to ALB)

resource "aws_ecs_service" "this" {
  name            = "procode-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn

  desired_count = 1
  launch_type   = "FARGATE"

  network_configuration {
    subnets         = var.subnets
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "procode-container"
    container_port   = 3000
  }

  depends_on = [var.listener_arn]
}

resource "aws_iam_role" "ecs_execution" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec_policy" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
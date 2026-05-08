resource "aws_ecs_cluster" "this" {
    name = "procode-cluster"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { 
        Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}


resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#The ECS Task definition is the container itself (blueprint which contains CPU/Memory?image/port/Logging)
resource "aws_cloudwatch_log_group" "ecs_app_logs" {
  name              = "/ecs/nginx-app-logs"
  retention_in_days = 30
}

resource "aws_ecs_task_definition" "nginx" {
  family                   = "nginx-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "nginx:latest"
      essential = true

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_app_logs.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "nginx"
        }
      }
    }
  ])
}

resource "aws_lb" "this" {
  name = "procode-alb"
  load_balancer_type = "application"
  subnets = local.public_subnets
  security_groups = [aws_security_group.alb_sg.id]

  # access_logs {
  #   bucket  = aws_s3_bucket.my_procode_bucket_for_logs.bucket
  #   prefix  = "alb-access-logs"
  #   enabled = true
  # }
  # depends_on = [ aws_s3_bucket_policy.logs_bucket_policy ]
}

resource "aws_lb_target_group" "this" {
  name = "nginx-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  target_type = "ip" #Required for Fargate

  health_check {
    path = "/"
  }

}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Congratulations you have successfully failed! Ancil will have to buy me lunch now :)"
      status_code  = "403"
    }
  }
}
resource "aws_lb_listener_rule" "allow_cloudfront" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  condition {
    http_header {
      http_header_name = "CloudEngineerSecret"
      values           = ["Vote-Radu-for-become-a-Cloud-Engineer"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_ecs_service" "nginx" {
  name = "nginx-service"
  cluster = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.nginx.arn
  desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    subnets = local.public_subnets
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name = "nginx"
    container_port = 80
  }
  depends_on = [ aws_lb_listener.http ]
  
}
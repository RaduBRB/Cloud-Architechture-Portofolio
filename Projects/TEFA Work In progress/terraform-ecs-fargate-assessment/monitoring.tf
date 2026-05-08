resource "aws_cloudwatch_metric_alarm" "ECS_Monitoring_CPU" {
  alarm_name          = "ECS_Monitoring"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60" 
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
  ClusterName = aws_ecs_cluster.this.name
  ServiceName = aws_ecs_service.nginx.name
}

  alarm_description   = "Alarm when CPU utilization exceeds 80%"
  
}

resource "aws_cloudwatch_metric_alarm" "ECS_Monitoring_Memory" {
  alarm_name          = "ECS_Monitoring"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "60" 
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
  ClusterName = aws_ecs_cluster.this.name
  ServiceName = aws_ecs_service.nginx.name
}

  alarm_description   = "Alarm when Memory utilization exceeds 80%"
  
}

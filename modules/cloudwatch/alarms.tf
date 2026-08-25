resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "nexus-ecs-memory-utilization-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Trigger alert when ECS cluster memory exceeds 85% for 2 consecutive minutes"
}

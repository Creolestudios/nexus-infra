output "ecs_memory_alarm_arn" {
  value       = aws_cloudwatch_metric_alarm.ecs_memory_high.arn
  description = "ARN of high memory utilization alarm"
}

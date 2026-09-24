output "dashboard_url" {
  value = "https://$${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=$${var.aws_region}#dashboards:name=$${aws_cloudwatch_dashboard.operations.dashboard_name}"
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "alarm_names" {
  value = [
    aws_cloudwatch_metric_alarm.ec2_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.rds_connections.alarm_name,
    aws_cloudwatch_metric_alarm.lambda_errors.alarm_name,
    aws_cloudwatch_metric_alarm.ec2_status.alarm_name,
    aws_cloudwatch_metric_alarm.ecs_errors.alarm_name
  ]
}

output "log_group_names" {
  value = [for lg in aws_cloudwatch_log_group.groups : lg.name]
}

locals {
  tags = {
    Project     = var.project
    Environment = "production"
    ManagedBy   = "terraform"
    Team        = "engineering"
    CostCenter  = "nexus-core"
  }
}

resource "aws_sns_topic" "alerts" {
  name = "nexus-ops-alerts"
  tags = local.tags
}

# Subscriber must confirm via email
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

locals {
  log_groups = [
    "/aws/lambda/nexus-email-trigger",
    "/aws/lambda/nexus-billing-webhook",
    "/aws/lambda/nexus-report-generator",
    "/ecs/nexus-platform",
    "/rds/nexus-db-primary",
    "/aws/apigateway/nexus-api"
  ]
}

resource "aws_cloudwatch_log_group" "groups" {
  count             = length(local.log_groups)
  name              = local.log_groups[count.index]
  retention_in_days = 30
  tags              = local.tags
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "nexus-ec2-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "missing"
  alarm_description   = "EC2 CPU is high"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  dimensions = {
    InstanceId = var.ec2_instance_id
  }
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "nexus-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 100
  alarm_description   = "RDS Connections are high"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "nexus-lambda-billing-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Lambda billing errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  dimensions = {
    FunctionName = "nexus-billing-webhook"
  }
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "ec2_status" {
  alarm_name          = "nexus-ec2-status-check-failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  treat_missing_data  = "breaching"
  alarm_description   = "EC2 Status Check Failed"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  dimensions = {
    InstanceId = var.ec2_instance_id
  }
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_errors" {
  alarm_name          = "nexus-ecs-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ECSErrors"
  namespace           = "NexusTech/Platform"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "ECS Application Errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  tags = local.tags
}

resource "aws_cloudwatch_log_metric_filter" "ecs_errors" {
  name           = "ecs-errors"
  pattern        = "ERROR"
  log_group_name = "/ecs/nexus-platform"
  metric_transformation {
    name      = "ECSErrors"
    namespace = "NexusTech/Platform"
    value     = "1"
  }
  depends_on = [aws_cloudwatch_log_group.groups]
}

resource "aws_cloudwatch_log_metric_filter" "lambda_billing_errors" {
  name           = "lambda-billing-webhook-errors"
  pattern        = "ERROR"
  log_group_name = "/aws/lambda/nexus-billing-webhook"
  metric_transformation {
    name      = "BillingWebhookErrors"
    namespace = "NexusTech/Platform"
    value     = "1"
  }
  depends_on = [aws_cloudwatch_log_group.groups]
}

resource "aws_cloudwatch_log_metric_filter" "rds_slow_query" {
  name           = "rds-slow-queries"
  pattern        = "slow_query"
  log_group_name = "/rds/nexus-db-primary"
  metric_transformation {
    name      = "SlowQueries"
    namespace = "NexusTech/Platform"
    value     = "1"
  }
  depends_on = [aws_cloudwatch_log_group.groups]
}

resource "aws_cloudwatch_dashboard" "operations" {
  dashboard_name = "NexusPlatform-Operations"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "NexusTech Platform - Operations Dashboard | Environment: Production"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 24
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", var.ec2_instance_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "EC2 CPU Utilization"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 24
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "nexus-email-trigger"],
            [".", "Errors", ".", "."],
            ["AWS/Lambda", "Invocations", "FunctionName", "nexus-billing-webhook"],
            [".", "Errors", ".", "."],
            ["AWS/Lambda", "Invocations", "FunctionName", "nexus-report-generator"],
            [".", "Errors", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda Invocations and Errors"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 13
        width  = 24
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.rds_identifier],
            [".", "FreeStorageSpace", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "RDS Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 19
        width  = 24
        height = 6
        properties = {
          metrics = [
            ["NexusTech/Platform", "ECSErrors"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ECS Custom Errors"
          period  = 300
        }
      }
    ]
  })
}

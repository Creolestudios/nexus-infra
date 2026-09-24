locals {
  tags = {
    Project     = var.project
    Environment = "production"
    ManagedBy   = "terraform"
    Team        = "engineering"
    CostCenter  = "nexus-core"
  }
}

resource "aws_budgets_budget" "monthly" {
  name              = "nexus-monthly-budget"
  budget_type       = "COST"
  limit_amount      = "500"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2026-09-01_00:00"

  cost_filter {
    name = "TagKeyValue"
    values = [
      "user:CostCenter$nexus-core"
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }

  tags = local.tags
}

resource "aws_ce_anomaly_monitor" "cost_monitor" {
  name              = "nexus-cost-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
  tags              = local.tags
}

resource "aws_ce_anomaly_subscription" "anomaly_alerts" {
  name             = "nexus-anomaly-alerts"
  frequency        = "DAILY"
  monitor_arn_list = [aws_ce_anomaly_monitor.cost_monitor.arn]

  threshold_expression {
    dimension {
      key            = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values         = ["50"]
      match_options  = ["GREATER_THAN_OR_EQUAL"]
    }
  }

  subscriber {
    type    = "EMAIL"
    address = var.alert_email
  }

  tags = local.tags
}

# NOTE: These cost allocation tags require the tag to exist on at least one resource first
resource "aws_ce_cost_allocation_tag" "tags" {
  for_each = toset(["CostCenter", "Environment", "Team", "Project"])
  tag_key  = each.key
  status   = "Active"
}

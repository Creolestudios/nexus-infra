# NexusTech Platform Infrastructure

This repository contains the Terraform configuration for the NexusTech Platform production environment.

## Prerequisites
- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- Python 3.x with boto3 installed (for log seeding)

## Quick Start

1. Initialize the project:
   ```bash
   make init
   ```
2. Create your `terraform.tfvars` from the example:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your actual values
   ```
3. Deploy the infrastructure:
   ```bash
   make full-deploy
   ```

## Teardown

To destroy the infrastructure:
```bash
make destroy
```

## Module Descriptions

- **networking**: Creates VPC, subnets, IGW, route tables, and security groups.
- **security**: Sets up IAM roles, instance profiles, and Secrets Manager.
- **compute**: Provisions EC2 instances, ECS cluster, and Lambda functions.
- **storage**: Configures S3 buckets, RDS PostgreSQL, DynamoDB, and ElastiCache Redis.
- **monitoring**: Configures CloudWatch Dashboards, Log Groups, Metric Filters, Alarms, and SNS for alerts.
- **billing**: Configures AWS Budgets and Cost Explorer anomaly detection.

## Estimated Cost Breakdown

- **Compute**: EC2 t3.micro (~$0.014/hr), ECS (Free for cluster), Lambda (Pay per request)
- **Database**: RDS db.t3.micro (~$0.018/hr), DynamoDB (Pay per request), ElastiCache cache.t3.micro (~$0.016/hr)
- **Storage**: S3 (Standard storage pricing)
- **Total Estimated Cost**: ~$1.20 per day

## CloudWatch Log Seeding

The `make full-deploy` command automatically runs `scripts/seed_logs.py` to generate realistic log events in CloudWatch over the past 7 days. This allows testing of alarms and metric filters immediately.

## Note on Billing Tags

The cost allocation tags created in the billing module require the tag to exist on at least one resource first, and then they must be manually activated in the AWS Billing Console if they do not activate automatically.

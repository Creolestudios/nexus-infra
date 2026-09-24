locals {
  tags = {
    Project     = var.project
    Environment = "production"
    ManagedBy   = "terraform"
    Team        = "engineering"
    CostCenter  = "nexus-core"
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "api_server" {
  ami                  = data.aws_ami.amazon_linux_2023.id
  instance_type        = "t3.micro"
  subnet_id            = var.public_subnet_ids[0]
  vpc_security_group_ids = [var.sg_web_id]
  iam_instance_profile = var.ec2_instance_profile_name

  user_data = <<-EOF
              #!/bin/bash
              dnf install -y nginx
              systemctl enable nginx
              systemctl start nginx
              echo "NexusTech Platform API - v2.1.0" > /var/www/html/index.html
              EOF

  tags = merge(local.tags, {
    Name    = "nexus-api-server"
    Service = "api"
  })
}

resource "aws_ecs_cluster" "platform" {
  name = "nexus-platform"
  tags = local.tags
}

resource "aws_ecs_cluster_capacity_providers" "platform" {
  cluster_name = aws_ecs_cluster.platform.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE_SPOT"
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "$${path.module}/lambda_payload.zip"
  source {
    content  = <<-EOF
      exports.handler = async (event) => {
        console.log('Event received:', JSON.stringify(event));
        return { statusCode: 200, body: JSON.stringify({ status: 'success' }) };
      };
    EOF
    filename = "index.js"
  }
}

resource "aws_lambda_function" "email_trigger" {
  function_name    = "nexus-email-trigger"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SERVICE     = "email-trigger"
      ENVIRONMENT = "production"
    }
  }

  tags = local.tags
}

resource "aws_lambda_function" "billing_webhook" {
  function_name    = "nexus-billing-webhook"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SERVICE     = "billing-webhook"
      ENVIRONMENT = "production"
    }
  }

  tags = local.tags
}

resource "aws_lambda_function" "report_generator" {
  function_name    = "nexus-report-generator"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SERVICE     = "report-generator"
      ENVIRONMENT = "production"
    }
  }

  tags = local.tags
}

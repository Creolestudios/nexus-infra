output "ec2_instance_id" {
  value = aws_instance.api_server.id
}

output "ec2_public_ip" {
  value = aws_instance.api_server.public_ip
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.platform.name
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.platform.arn
}

output "lambda_function_names" {
  value = [
    aws_lambda_function.email_trigger.function_name,
    aws_lambda_function.billing_webhook.function_name,
    aws_lambda_function.report_generator.function_name
  ]
}

output "lambda_function_arns" {
  value = {
    email_trigger    = aws_lambda_function.email_trigger.arn
    billing_webhook  = aws_lambda_function.billing_webhook.arn
    report_generator = aws_lambda_function.report_generator.arn
  }
}

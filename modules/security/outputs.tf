output "ec2_instance_profile_name" {
  value = aws_iam_instance_profile.ec2_profile.name
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda_role.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}

output "secret_arns" {
  value = {
    db_credentials   = aws_secretsmanager_secret.db_credentials.arn
    stripe_api_key   = aws_secretsmanager_secret.stripe_api_key.arn
    sendgrid_api_key = aws_secretsmanager_secret.sendgrid_api_key.arn
  }
}

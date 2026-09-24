output "vpc_id" {
  value = module.networking.vpc_id
}

output "ec2_instance_id" {
  value = module.compute.ec2_instance_id
}

output "ec2_public_ip" {
  value = module.compute.ec2_public_ip
}

output "ecs_cluster_name" {
  value = module.compute.ecs_cluster_name
}

output "rds_endpoint" {
  value = module.storage.rds_endpoint
}

output "elasticache_primary_endpoint" {
  value = module.storage.elasticache_endpoint
}

output "s3_bucket_names" {
  value = module.storage.s3_bucket_names
}

output "dynamodb_table_name" {
  value = module.storage.dynamodb_table_name
}

output "cloudwatch_dashboard_url" {
  value = module.monitoring.dashboard_url
}

output "lambda_function_names" {
  value = module.compute.lambda_function_names
}

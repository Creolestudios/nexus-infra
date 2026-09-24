output "s3_bucket_names" {
  value = [
    aws_s3_bucket.user_uploads.id,
    aws_s3_bucket.logs.id,
    aws_s3_bucket.assets.id,
    aws_s3_bucket.backups.id
  ]
}

output "s3_bucket_arns" {
  value = {
    user_uploads = aws_s3_bucket.user_uploads.arn
    logs         = aws_s3_bucket.logs.arn
    assets       = aws_s3_bucket.assets.arn
    backups      = aws_s3_bucket.backups.arn
  }
}

output "rds_endpoint" {
  value = aws_db_instance.primary.endpoint
}

output "rds_port" {
  value = aws_db_instance.primary.port
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.events.name
}

output "elasticache_endpoint" {
  value = aws_elasticache_cluster.primary.cache_nodes[0].address
}

output "elasticache_port" {
  value = aws_elasticache_cluster.primary.cache_nodes[0].port
}

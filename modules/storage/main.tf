locals {
  tags = {
    Project     = var.project
    Environment = "production"
    ManagedBy   = "terraform"
    Team        = "engineering"
    CostCenter  = "nexus-core"
  }
  bucket_names = [
    "$${var.project}-user-uploads-$${var.aws_account_id}",
    "$${var.project}-logs-$${var.aws_account_id}",
    "$${var.project}-assets-$${var.aws_account_id}",
    "$${var.project}-backups-$${var.aws_account_id}"
  ]
}

resource "aws_s3_bucket" "user_uploads" {
  bucket = local.bucket_names[0]
  tags   = merge(local.tags, { Service = "storage" })
}

resource "aws_s3_bucket_versioning" "user_uploads" {
  bucket = aws_s3_bucket.user_uploads.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "user_uploads" {
  bucket = aws_s3_bucket.user_uploads.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "user_uploads" {
  bucket                  = aws_s3_bucket.user_uploads.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "logs" {
  bucket = local.bucket_names[1]
  tags   = merge(local.tags, { Service = "storage" })
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "assets" {
  bucket = local.bucket_names[2]
  tags   = merge(local.tags, { Service = "storage" })
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "assets" {
  bucket = aws_s3_bucket.assets.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "$${aws_s3_bucket.assets.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::$${var.aws_account_id}:distribution/PLACEHOLDER"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket" "backups" {
  bucket = local.bucket_names[3]
  tags   = merge(local.tags, { Service = "storage" })
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_db_subnet_group" "rds" {
  name       = "nexus-db-subnet-group"
  subnet_ids = var.public_subnet_ids
  tags       = merge(local.tags, { Service = "database" })
}

resource "aws_db_instance" "primary" {
  identifier             = "nexus-db-primary"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = "nexusdb"
  username               = "nexusadmin"
  password               = var.db_password
  multi_az               = false
  publicly_accessible    = false
  vpc_security_group_ids = [var.sg_rds_id]
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  skip_final_snapshot    = true
  backup_retention_period= 7
  tags                   = merge(local.tags, { Name = "nexus-db-primary", Service = "database" })
}

resource "aws_dynamodb_table" "events" {
  name         = "nexus-events"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "eventId"
  range_key    = "timestamp"

  attribute {
    name = "eventId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  tags = merge(local.tags, { Service = "events" })
}

resource "aws_elasticache_subnet_group" "cache" {
  name       = "nexus-cache-subnet-group"
  subnet_ids = var.public_subnet_ids
  tags       = merge(local.tags, { Service = "cache" })
}

resource "aws_elasticache_cluster" "primary" {
  cluster_id           = "nexus-cache-primary"
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.cache.name
  security_group_ids   = [var.sg_cache_id]
  tags                 = merge(local.tags, { Name = "nexus-cache-primary", Service = "cache" })
}

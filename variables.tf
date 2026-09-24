variable "aws_region"      { default = "us-east-1" }
variable "project"         { default = "nexus-platform" }
variable "aws_account_id"  { description = "Your AWS account ID (used in S3 bucket names)" }
variable "alert_email"     { description = "Email for billing and alarm alerts" }
variable "db_password"     { sensitive = true; description = "RDS master password" }

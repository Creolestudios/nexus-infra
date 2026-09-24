variable "project" {
  type = string
}
variable "aws_region" {
  type = string
}
variable "ec2_instance_id" {
  type = string
}
variable "rds_identifier" {
  type = string
}
variable "lambda_function_names" {
  type = list(string)
}
variable "alert_email" {
  type = string
}

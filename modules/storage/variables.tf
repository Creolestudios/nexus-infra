variable "project" {
  type = string
}
variable "aws_account_id" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "public_subnet_ids" {
  type = list(string)
}
variable "sg_rds_id" {
  type = string
}
variable "sg_cache_id" {
  type = string
}
variable "db_password" {
  type      = string
  sensitive = true
}

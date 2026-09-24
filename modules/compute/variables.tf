variable "project" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "public_subnet_ids" {
  type = list(string)
}
variable "sg_web_id" {
  type = string
}
variable "ec2_instance_profile_name" {
  type = string
}
variable "lambda_role_arn" {
  type = string
}

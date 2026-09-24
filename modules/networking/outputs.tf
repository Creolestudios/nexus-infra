output "vpc_id" {
  value = aws_vpc.main.id
}
output "public_subnet_ids" {
  value = [aws_subnet.public_1a.id, aws_subnet.public_1b.id]
}
output "sg_web_id" {
  value = aws_security_group.web.id
}
output "sg_rds_id" {
  value = aws_security_group.rds.id
}
output "sg_cache_id" {
  value = aws_security_group.cache.id
}

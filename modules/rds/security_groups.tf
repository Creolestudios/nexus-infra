resource "aws_security_group_rule" "rds_ingress_app" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = "sg-01a2b3c4d5e6f7g8h"
  cidr_blocks       = ["10.0.1.0/24", "10.0.2.0/24"]
  description       = "Allow inbound PostgreSQL connections strictly from private backend subnets"
}

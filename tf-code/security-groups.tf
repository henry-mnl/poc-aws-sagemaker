resource "aws_security_group" "endpoint-sg" {
  name        = "endpoint-sg"
  description = "Security group for VPC Endpoint"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #allow all inbound traffic. Can be scoped further. May not be needed since it's deployed in private subnets.
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] #allow all outbound traffic, adjust as needed for better security
  }
}

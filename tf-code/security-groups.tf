resource "aws_security_group" "endpoint-sg" {
  name        = "endpoint-sg"
  description = "Security group for VPC Endpoint"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #allow all inbound traffic, adjust as needed for better security
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] #allow all outbound traffic, adjust as needed for better security
  }
}

resource "aws_security_group" "sagemaker-domain-sg" {
  name        = "sagemaker-domain-sg"
  description = "Security group for SageMaker Domain"
  vpc_id      = module.vpc.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "sagemaker-domain-sg-ingress-allow-intra-sagemaker" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.sagemaker-domain-sg.id
  source_security_group_id = aws_security_group.sagemaker-domain-sg.id
}

####################################################################################################
# VPC
####################################################################################################
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "prod-apne-vpc"
  cidr = "10.0.0.0/21"
  azs  = ["ap-southeast-1a", "ap-southeast-1c", "ap-southeast-1d"]
  #   public_subnets         = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"] #uncomment when need to add internet connection
  private_subnets        = ["10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24"]
  create_igw             = false #set to true if you need Internet Gateway, default to true
  create_egress_only_igw = false #set to true if you need Egress Only Internet Gateway, default to false
  enable_nat_gateway     = false #set to true if you need NAT Gateway, default to true
  one_nat_gateway_per_az = false
  single_nat_gateway     = true
  enable_dns_hostnames   = true
}

####################################################################################################
# VPC Endpoint - S3
####################################################################################################
resource "aws_vpc_endpoint" "s3" {
  vpc_id          = module.vpc.vpc_id
  service_name    = "com.amazonaws.${local.region}.s3"
  route_table_ids = module.vpc.public_route_table_ids + module.vpc.private_route_table_ids #associate with both public and private route tables
}

####################################################################################################
# VPC Endpoints - SageMaker
####################################################################################################
resource "aws_vpc_endpoint" "sagemaker-api" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${local.region}.sagemaker.api"
  subnet_ids          = module.vpc.private_subnets          #associate with private subnets
  security_group_ids  = [aws_security_group.endpoint-sg.id] #associate with the security group created for the endpoint
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "sagemaker-runtime" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${local.region}.sagemaker.runtime"
  subnet_ids          = module.vpc.private_subnets          #associate with private subnets
  security_group_ids  = [aws_security_group.endpoint-sg.id] #associate with the security group created for the endpoint
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "sagemaker-studio" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "aws.sagemaker.${local.region}.studio"
  subnet_ids          = module.vpc.private_subnets          #associate with private subnets
  security_group_ids  = [aws_security_group.endpoint-sg.id] #associate with the security group created for the endpoint
  private_dns_enabled = true
}

####################################################################################################
# VPC Endpoints - Bedrock
####################################################################################################
resource "aws_vpc_endpoint" "bedrock" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${local.region}.bedrock"
  subnet_ids         = module.vpc.private_subnets          #associate with private subnets
  security_group_ids = [aws_security_group.endpoint-sg.id] #associate with the security group created for the endpoint
}

####################################################################################################
# VPC Endpoints - CloudWatch Logs
####################################################################################################
resource "aws_vpc_endpoint" "cloudwatch-logs" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${local.region}.logs"
  subnet_ids          = module.vpc.private_subnets          #associate with private subnets
  security_group_ids  = [aws_security_group.endpoint-sg.id] #associate with the security group created for the endpoint
  private_dns_enabled = true
}

####################################################################################################
# VPC Endpoints - Monitoring
####################################################################################################
resource "aws_vpc_endpoint" "monitoring" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${local.region}.monitoring"
  subnet_ids          = module.vpc.private_subnets          #associate with private subnets
  security_group_ids  = [aws_security_group.endpoint-sg.id] #associate with the security group created for the endpoint
  private_dns_enabled = true
}

####################################################################################################
# VPC Endpoints - sts
####################################################################################################
resource "aws_vpc_endpoint" "sts" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${local.region}.sts"
  subnet_ids          = module.vpc.private_subnets          #associate with private subnets
  security_group_ids  = [aws_security_group.endpoint-sg.id] #associate with the security group created for the endpoint
  private_dns_enabled = true
}

####################################################################################################
# VPC Endpoints - ECR
####################################################################################################
resource "aws_vpc_endpoint" "ecr-api" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${local.region}.ecr.api"
  subnet_ids          = module.vpc.private_subnets          #associate with private subnets
  security_group_ids  = [aws_security_group.endpoint-sg.id] #associate with the security group created for the endpoint
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr-dkr" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${local.region}.ecr.dkr"
  subnet_ids          = module.vpc.private_subnets          #associate with private subnets
  security_group_ids  = [aws_security_group.endpoint-sg.id] #associate with the security group created for the endpoint
  private_dns_enabled = true
}

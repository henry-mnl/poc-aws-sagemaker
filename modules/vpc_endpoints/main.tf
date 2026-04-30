data "aws_region" "current" {}

# Derive the route table associated with each private subnet so the S3 Gateway
# endpoint can be attached to them automatically – the caller only needs to pass
# subnet_ids (no separate route_table_ids variable needed).
data "aws_route_table" "selected" {
  for_each  = toset(var.subnet_ids)
  subnet_id = each.value
}

locals {
  name_prefix     = "${var.project_name}-${var.environment}"
  region          = data.aws_region.current.id
  route_table_ids = distinct([for rt in data.aws_route_table.selected : rt.id])
}

# ── Security group for VPC Interface endpoint ENIs ────────────────────────────
# A dedicated SG is attached to every Interface endpoint ENI.  Only HTTPS
# traffic originating from the SageMaker security group (Studio apps, notebook
# instances, training containers) is allowed in.

resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.name_prefix}-vpc-endpoints-sg"
  description = "Controls inbound HTTPS to VPC Interface endpoint ENIs from SageMaker workloads"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_https_from_sagemaker" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = var.sagemaker_sg_id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Allow HTTPS from SageMaker domain and training nodes"
}

# ── S3 Gateway endpoint ────────────────────────────────────────────────────────
# Routes all S3 traffic from the private subnets through the AWS backbone –
# no internet path, no data-transfer cost per GB.  Gateway endpoints attach to
# route tables (not ENIs) so they require no security group.

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${local.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = local.route_table_ids

  tags = merge(var.tags, { Name = "${local.name_prefix}-s3-gateway-endpoint" })
}

# ── SageMaker API Interface endpoint ─────────────────────────────────────────
# Allows private API calls (CreateTrainingJob, CreateEndpoint, etc.) from inside
# the VPC without routing through the public internet.

resource "aws_vpc_endpoint" "sagemaker_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${local.region}.sagemaker.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${local.name_prefix}-sagemaker-api-endpoint" })
}

# ── SageMaker Runtime Interface endpoint ─────────────────────────────────────
# Required for InvokeEndpoint calls from inside the VPC.

resource "aws_vpc_endpoint" "sagemaker_runtime" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${local.region}.sagemaker.runtime"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${local.name_prefix}-sagemaker-runtime-endpoint" })
}

# ── SageMaker Studio Interface endpoint ──────────────────────────────────────
# Required for VPC-only Studio access – the browser is redirected to a
# *.studio.*.sagemaker.aws hostname that resolves to this endpoint.

resource "aws_vpc_endpoint" "sagemaker_studio" {
  vpc_id              = var.vpc_id
  service_name        = "aws.sagemaker.${local.region}.studio"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${local.name_prefix}-sagemaker-studio-endpoint" })
}

# ── ECR API Interface endpoint ────────────────────────────────────────────────
# Used to authenticate and retrieve image manifests before pulling layers.

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${local.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${local.name_prefix}-ecr-api-endpoint" })
}

# ── ECR Docker Registry Interface endpoint ────────────────────────────────────
# Used to pull actual container image layers; works together with ecr.api and
# the S3 Gateway endpoint (ECR stores layers in S3 under the hood).

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${local.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${local.name_prefix}-ecr-dkr-endpoint" })
}

# ── CloudWatch Logs Interface endpoint ───────────────────────────────────────
# Training jobs and Studio kernels write logs to CloudWatch Logs.

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${local.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${local.name_prefix}-logs-endpoint" })
}

# ── CloudWatch Monitoring Interface endpoint ─────────────────────────────────
# Publishes custom and built-in metrics (e.g. training loss, GPU utilisation).

resource "aws_vpc_endpoint" "monitoring" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${local.region}.monitoring"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${local.name_prefix}-monitoring-endpoint" })
}

# ── STS Interface endpoint ────────────────────────────────────────────────────
# Required for sts:AssumeRole calls made by SageMaker services and SDK code
# running inside the VPC (e.g. boto3 credential refresh in Studio / training).

resource "aws_vpc_endpoint" "sts" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${local.region}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${local.name_prefix}-sts-endpoint" })
}

# ── Bedrock Interface endpoint ────────────────────────────────────────────────
# Allows Studio notebooks and training code to call Amazon Bedrock foundation
# model APIs (InvokeModel, Converse, etc.) without leaving the VPC.

resource "aws_vpc_endpoint" "bedrock" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${local.region}.bedrock"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${local.name_prefix}-bedrock-endpoint" })
}

# ── Bedrock Runtime Interface endpoint ───────────────────────────────────────
# The data-plane endpoint used by boto3 bedrock-runtime client
# (InvokeModel, InvokeModelWithResponseStream, Converse, ConverseStream).
# Both bedrock and bedrock-runtime endpoints are required for full SDK support.

resource "aws_vpc_endpoint" "bedrock_runtime" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${local.region}.bedrock-runtime"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${local.name_prefix}-bedrock-runtime-endpoint" })
}

output "vpc_endpoint_sg_id" {
  description = "ID of the security group attached to all VPC Interface endpoint ENIs"
  value       = aws_security_group.vpc_endpoints.id
}

output "s3_endpoint_id" {
  description = "ID of the S3 Gateway endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "sagemaker_api_endpoint_id" {
  description = "ID of the SageMaker API Interface endpoint"
  value       = aws_vpc_endpoint.sagemaker_api.id
}

output "sagemaker_runtime_endpoint_id" {
  description = "ID of the SageMaker Runtime Interface endpoint"
  value       = aws_vpc_endpoint.sagemaker_runtime.id
}

output "sagemaker_studio_endpoint_id" {
  description = "ID of the SageMaker Studio Interface endpoint"
  value       = aws_vpc_endpoint.sagemaker_studio.id
}

output "ecr_api_endpoint_id" {
  description = "ID of the ECR API Interface endpoint"
  value       = aws_vpc_endpoint.ecr_api.id
}

output "ecr_dkr_endpoint_id" {
  description = "ID of the ECR DKR Interface endpoint"
  value       = aws_vpc_endpoint.ecr_dkr.id
}

output "logs_endpoint_id" {
  description = "ID of the CloudWatch Logs Interface endpoint"
  value       = aws_vpc_endpoint.logs.id
}

output "monitoring_endpoint_id" {
  description = "ID of the CloudWatch Monitoring Interface endpoint"
  value       = aws_vpc_endpoint.monitoring.id
}

output "sts_endpoint_id" {
  description = "ID of the STS Interface endpoint"
  value       = aws_vpc_endpoint.sts.id
}

output "bedrock_endpoint_id" {
  description = "ID of the Bedrock Interface endpoint (control plane)"
  value       = aws_vpc_endpoint.bedrock.id
}

output "bedrock_runtime_endpoint_id" {
  description = "ID of the Bedrock Runtime Interface endpoint (data plane – InvokeModel, Converse)"
  value       = aws_vpc_endpoint.bedrock_runtime.id
}

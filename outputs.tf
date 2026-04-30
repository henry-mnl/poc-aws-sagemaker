# ── IAM ───────────────────────────────────────────────────────────────────────

output "sagemaker_execution_role_arn" {
  description = "ARN of the SageMaker Studio execution IAM role"
  value       = module.iam.sagemaker_execution_role_arn
}

output "training_execution_role_arn" {
  description = "ARN of the dedicated SageMaker training execution IAM role"
  value       = module.iam.training_execution_role_arn
}

output "inference_execution_role_arn" {
  description = "ARN of the dedicated SageMaker inference execution IAM role"
  value       = module.iam.inference_execution_role_arn
}

output "data_scientists_group_name" {
  description = "IAM group name for Data Scientists"
  value       = module.iam.data_scientists_group_name
}

output "ml_engineers_group_name" {
  description = "IAM group name for ML Engineers"
  value       = module.iam.ml_engineers_group_name
}

output "devops_group_name" {
  description = "IAM group name for DevOps"
  value       = module.iam.devops_group_name
}

# ── SageMaker ─────────────────────────────────────────────────────────────────

output "sagemaker_domain_id" {
  description = "ID of the SageMaker Studio domain"
  value       = module.sagemaker.domain_id
}

output "sagemaker_domain_url" {
  description = "URL of the SageMaker Studio domain"
  value       = module.sagemaker.domain_url
}

output "sagemaker_s3_bucket" {
  description = "Name of the S3 bucket used for training data and model artifacts"
  value       = module.sagemaker.s3_bucket_name
}

output "sagemaker_training_job_name" {
  description = "Name of the example SageMaker training job (spot instances)"
  value       = module.sagemaker.training_job_name
}

output "sagemaker_endpoint_name" {
  description = "Name of the SageMaker inference endpoint (on-demand instances + Application Auto Scaling)"
  value       = module.sagemaker.endpoint_name
}

output "sagemaker_gpu_endpoint_name" {
  description = "Name of the GPU inference endpoint (NVIDIA MIG isolation + managed_instance_scaling)"
  value       = module.sagemaker.gpu_endpoint_name
}

# ── VPC Endpoints ─────────────────────────────────────────────────────────────

output "vpc_endpoint_sg_id" {
  description = "Security group ID attached to all VPC Interface endpoint ENIs"
  value       = module.vpc_endpoints.vpc_endpoint_sg_id
}

output "s3_vpc_endpoint_id" {
  description = "ID of the S3 Gateway endpoint"
  value       = module.vpc_endpoints.s3_endpoint_id
}

output "sagemaker_api_endpoint_id" {
  description = "ID of the SageMaker API Interface endpoint"
  value       = module.vpc_endpoints.sagemaker_api_endpoint_id
}

output "sagemaker_runtime_endpoint_id" {
  description = "ID of the SageMaker Runtime Interface endpoint"
  value       = module.vpc_endpoints.sagemaker_runtime_endpoint_id
}

output "sagemaker_studio_endpoint_id" {
  description = "ID of the SageMaker Studio Interface endpoint"
  value       = module.vpc_endpoints.sagemaker_studio_endpoint_id
}

output "ecr_api_endpoint_id" {
  description = "ID of the ECR API Interface endpoint"
  value       = module.vpc_endpoints.ecr_api_endpoint_id
}

output "ecr_dkr_endpoint_id" {
  description = "ID of the ECR DKR Interface endpoint"
  value       = module.vpc_endpoints.ecr_dkr_endpoint_id
}

output "logs_endpoint_id" {
  description = "ID of the CloudWatch Logs Interface endpoint"
  value       = module.vpc_endpoints.logs_endpoint_id
}

output "monitoring_endpoint_id" {
  description = "ID of the CloudWatch Monitoring Interface endpoint"
  value       = module.vpc_endpoints.monitoring_endpoint_id
}

output "sts_endpoint_id" {
  description = "ID of the STS Interface endpoint"
  value       = module.vpc_endpoints.sts_endpoint_id
}

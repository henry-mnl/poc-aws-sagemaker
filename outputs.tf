# ── IAM ───────────────────────────────────────────────────────────────────────

output "sagemaker_execution_role_arn" {
  description = "ARN of the SageMaker execution IAM role"
  value       = module.iam.sagemaker_execution_role_arn
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
  description = "Name of the SageMaker inference endpoint (on-demand instances)"
  value       = module.sagemaker.endpoint_name
}

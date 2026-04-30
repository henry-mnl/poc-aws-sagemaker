output "domain_id" {
  description = "ID of the SageMaker Studio domain"
  value       = aws_sagemaker_domain.this.id
}

output "domain_url" {
  description = "URL of the SageMaker Studio domain"
  value       = aws_sagemaker_domain.this.url
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket used for training data and model artifacts"
  value       = aws_s3_bucket.sagemaker.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.sagemaker.arn
}

output "security_group_id" {
  description = "ID of the SageMaker security group"
  value       = aws_security_group.sagemaker.id
}

output "training_job_name" {
  description = "Name of the spot training job (null if model_artifact_s3_uri is set)"
  value       = local.deploy_model ? null : aws_sagemaker_training_job.spot[0].training_job_name
}

output "model_name" {
  description = "Name of the SageMaker model (null if model_artifact_s3_uri is not set)"
  value       = local.deploy_model ? aws_sagemaker_model.this[0].name : null
}

output "endpoint_config_name" {
  description = "Name of the SageMaker endpoint configuration (null if model_artifact_s3_uri is not set)"
  value       = local.deploy_model ? aws_sagemaker_endpoint_configuration.this[0].name : null
}

output "endpoint_name" {
  description = "Name of the SageMaker inference endpoint (null if model_artifact_s3_uri is not set)"
  value       = local.deploy_model ? aws_sagemaker_endpoint.this[0].name : null
}

output "gpu_endpoint_name" {
  description = "Name of the GPU inference endpoint with managed_instance_scaling (null if gpu_model_artifact_s3_uri is not set)"
  value       = local.deploy_gpu ? aws_sagemaker_endpoint.gpu[0].name : null
}

output "gpu_endpoint_config_name" {
  description = "Name of the GPU endpoint configuration (null if gpu_model_artifact_s3_uri is not set)"
  value       = local.deploy_gpu ? aws_sagemaker_endpoint_configuration.gpu[0].name : null
}

output "user_profiles" {
  description = "Map of user profile names created in the SageMaker domain"
  value = {
    data_scientist = aws_sagemaker_user_profile.data_scientist.user_profile_name
    ml_engineer    = aws_sagemaker_user_profile.ml_engineer.user_profile_name
    devops         = aws_sagemaker_user_profile.devops.user_profile_name
  }
}

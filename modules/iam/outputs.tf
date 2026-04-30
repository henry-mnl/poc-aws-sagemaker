output "sagemaker_execution_role_arn" {
  description = "ARN of the SageMaker Studio execution IAM role (used by domain and user profiles)"
  value       = aws_iam_role.sagemaker_execution.arn
}

output "sagemaker_execution_role_name" {
  description = "Name of the SageMaker Studio execution IAM role"
  value       = aws_iam_role.sagemaker_execution.name
}

output "training_execution_role_arn" {
  description = "ARN of the dedicated SageMaker training execution IAM role"
  value       = aws_iam_role.sagemaker_training_execution.arn
}

output "training_execution_role_name" {
  description = "Name of the dedicated SageMaker training execution IAM role"
  value       = aws_iam_role.sagemaker_training_execution.name
}

output "inference_execution_role_arn" {
  description = "ARN of the dedicated SageMaker inference execution IAM role"
  value       = aws_iam_role.sagemaker_inference_execution.arn
}

output "inference_execution_role_name" {
  description = "Name of the dedicated SageMaker inference execution IAM role"
  value       = aws_iam_role.sagemaker_inference_execution.name
}

output "data_scientists_group_name" {
  description = "IAM group name for Data Scientists"
  value       = aws_iam_group.data_scientists.name
}

output "data_scientists_group_arn" {
  description = "IAM group ARN for Data Scientists"
  value       = aws_iam_group.data_scientists.arn
}

output "ml_engineers_group_name" {
  description = "IAM group name for ML Engineers"
  value       = aws_iam_group.ml_engineers.name
}

output "ml_engineers_group_arn" {
  description = "IAM group ARN for ML Engineers"
  value       = aws_iam_group.ml_engineers.arn
}

output "devops_group_name" {
  description = "IAM group name for DevOps"
  value       = aws_iam_group.devops.name
}

output "devops_group_arn" {
  description = "IAM group ARN for DevOps"
  value       = aws_iam_group.devops.arn
}

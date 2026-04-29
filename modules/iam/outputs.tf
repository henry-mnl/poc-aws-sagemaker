output "sagemaker_execution_role_arn" {
  description = "ARN of the SageMaker execution IAM role"
  value       = aws_iam_role.sagemaker_execution.arn
}

output "sagemaker_execution_role_name" {
  description = "Name of the SageMaker execution IAM role"
  value       = aws_iam_role.sagemaker_execution.name
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

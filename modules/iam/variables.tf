variable "project_name" {
  description = "Project name prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
}

variable "tags" {
  description = "Map of tags applied to all resources in this module"
  type        = map(string)
  default     = {}
}

variable "data_scientist_users" {
  description = "IAM user names to add to the Data Scientists group"
  type        = list(string)
  default     = []
}

variable "ml_engineer_users" {
  description = "IAM user names to add to the ML Engineers group"
  type        = list(string)
  default     = []
}

variable "devops_users" {
  description = "IAM user names to add to the DevOps group"
  type        = list(string)
  default     = []
}

variable "curated_data_s3_arns" {
  description = "List of S3 ARNs (bucket or prefix) that Data Scientists are allowed to read as curated datasets. Defaults to all S3 resources; tighten in production."
  type        = list(string)
  default     = ["*"]
}

variable "training_s3_arns" {
  description = "List of S3 ARNs (bucket or prefix) that Data Scientists are allowed to write training artifacts to (input uploads, output, checkpoints). Defaults to all S3 resources; tighten in production."
  type        = list(string)
  default     = ["*"]
}

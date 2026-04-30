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

# ── Networking ────────────────────────────────────────────────────────────────

variable "vpc_id" {
  description = "VPC ID in which the endpoints will be created"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs where Interface endpoint ENIs will be placed"
  type        = list(string)
}

variable "sagemaker_sg_id" {
  description = "ID of the SageMaker security group whose members are allowed to reach the VPC endpoint ENIs on HTTPS"
  type        = string
}

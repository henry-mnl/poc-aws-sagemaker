variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project, used as a prefix for all resource names"
  type        = string
  default     = "poc-sagemaker"
}

variable "environment" {
  description = "Deployment environment name (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ── Networking ────────────────────────────────────────────────────────────────

variable "vpc_id" {
  description = "VPC ID in which the SageMaker domain and notebook instances will be placed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the SageMaker domain (must be in the given VPC)"
  type        = list(string)
}

# ── SageMaker domain / workspace ─────────────────────────────────────────────

variable "sagemaker_domain_name" {
  description = "Display name for the SageMaker Studio domain"
  type        = string
  default     = "poc-sagemaker-domain"
}

variable "studio_kernel_instance_type" {
  description = "Default SageMaker Studio kernel gateway instance type"
  type        = string
  default     = "ml.t3.medium"
}

# ── Training (spot) ───────────────────────────────────────────────────────────

variable "training_instance_type" {
  description = "EC2 instance type used for SageMaker training jobs (Managed Spot Training)"
  type        = string
  default     = "ml.m5.xlarge"
}

variable "training_max_run_seconds" {
  description = "Maximum allowed run time in seconds for a training job"
  type        = number
  default     = 3600
}

variable "training_max_wait_seconds" {
  description = "Maximum time in seconds to wait for a Managed Spot Training job to complete (must be >= training_max_run_seconds)"
  type        = number
  default     = 7200
}

variable "training_volume_size_gb" {
  description = "Size in GB of the storage volume attached to training instances"
  type        = number
  default     = 30
}

# ── Inference (on-demand) ─────────────────────────────────────────────────────

variable "container_image_uri" {
  description = "Full URI of the SageMaker container image for training and inference. You can retrieve the correct URI for your region from https://docs.aws.amazon.com/sagemaker/latest/dg/sagemaker-algo-docker-registry-paths.html"
  type        = string
}

variable "model_artifact_s3_uri" {
  description = "S3 URI of the trained model artifact (e.g. s3://bucket/prefix/model.tar.gz). Leave empty to skip model and endpoint creation."
  type        = string
  default     = ""
}

variable "endpoint_instance_type" {
  description = "EC2 instance type for the SageMaker inference endpoint (on-demand)"
  type        = string
  default     = "ml.m5.large"
}

variable "endpoint_initial_instance_count" {
  description = "Initial number of instances behind the endpoint"
  type        = number
  default     = 1
}

variable "endpoint_min_capacity" {
  description = "Minimum instance count for endpoint auto-scaling"
  type        = number
  default     = 1
}

variable "endpoint_max_capacity" {
  description = "Maximum instance count for endpoint auto-scaling"
  type        = number
  default     = 4
}

variable "autoscaling_target_invocations_per_instance" {
  description = "Target number of invocations per instance used by the target-tracking auto-scaling policy"
  type        = number
  default     = 70
}

variable "autoscaling_scale_in_cooldown_seconds" {
  description = "Cooldown period in seconds after a scale-in activity"
  type        = number
  default     = 300
}

variable "autoscaling_scale_out_cooldown_seconds" {
  description = "Cooldown period in seconds after a scale-out activity"
  type        = number
  default     = 60
}

# ── IAM group membership (optional) ──────────────────────────────────────────

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

variable "project_name" {
  description = "Project name prefix for all resource names"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Map of tags applied to all resources in this module"
  type        = map(string)
  default     = {}
}

####################################################################################################
# Networking
####################################################################################################
variable "vpc_id" {
  description = "VPC ID for the SageMaker domain and security group"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs used by the SageMaker domain"
  type        = list(string)
}

####################################################################################################
# Sagemaker Domain Name
####################################################################################################
variable "domain_name" {
  description = "Display name for the SageMaker Studio domain"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the IAM role assumed by SageMaker for all operations"
  type        = string
}

variable "training_role_arn" {
  description = "ARN of the IAM role assumed by SageMaker for training jobs"
  type        = string
}

variable "inference_role_arn" {
  description = "ARN of the IAM role assumed by SageMaker for inference jobs"
  type        = string
}

variable "studio_kernel_instance_type" {
  description = "Default instance type for SageMaker Studio kernel gateway apps"
  type        = string
  default     = "ml.t3.medium"
}

####################################################################################################
# Spot Training Variables
####################################################################################################
variable "training_instance_type" {
  description = "EC2 instance type for SageMaker training jobs (Managed Spot Training)"
  type        = string
  default     = "ml.m5.xlarge"
}

variable "training_max_run_seconds" {
  description = "Maximum allowed run time in seconds for a training job"
  type        = number
  default     = 3600
}

variable "training_max_wait_seconds" {
  description = "Maximum time to wait for a spot training job (must be >= training_max_run_seconds)"
  type        = number
  default     = 7200
}

variable "training_volume_size_gb" {
  description = "Storage volume size in GB attached to each training instance"
  type        = number
  default     = 30
}

####################################################################################################
# Sagemaker Endpoint Variables
####################################################################################################
variable "endpoint_instance_type" {
  description = "EC2 instance type for the SageMaker inference endpoint (on-demand)"
  type        = string
  default     = "ml.m5.large"
}

variable "endpoint_initial_instance_count" {
  description = "Initial instance count for the endpoint"
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
  description = "Target invocations per instance for the target-tracking auto-scaling policy"
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

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
variable "container_image_uri" {
  description = "Full URI of the SageMaker container image used for both training and inference (e.g. the XGBoost built-in algorithm image for your region)."
  type        = string
}

variable "model_artifact_s3_uri" {
  description = "S3 URI of the trained model artifact. When empty, model/endpoint resources are skipped."
  type        = string
  default     = ""
}

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

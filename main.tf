locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ── IAM module ────────────────────────────────────────────────────────────────

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.tags

  data_scientist_users = var.data_scientist_users
  ml_engineer_users    = var.ml_engineer_users
  devops_users         = var.devops_users
}

# ── SageMaker module ──────────────────────────────────────────────────────────

module "sagemaker" {
  source = "./modules/sagemaker"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.tags

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  domain_name                 = var.sagemaker_domain_name
  execution_role_arn          = module.iam.sagemaker_execution_role_arn
  studio_kernel_instance_type = var.studio_kernel_instance_type

  # Spot training
  container_image_uri       = var.container_image_uri
  training_instance_type    = var.training_instance_type
  training_max_run_seconds  = var.training_max_run_seconds
  training_max_wait_seconds = var.training_max_wait_seconds
  training_volume_size_gb   = var.training_volume_size_gb

  # On-demand inference + autoscaling
  model_artifact_s3_uri                       = var.model_artifact_s3_uri
  endpoint_instance_type                      = var.endpoint_instance_type
  endpoint_initial_instance_count             = var.endpoint_initial_instance_count
  endpoint_min_capacity                       = var.endpoint_min_capacity
  endpoint_max_capacity                       = var.endpoint_max_capacity
  autoscaling_target_invocations_per_instance = var.autoscaling_target_invocations_per_instance
  autoscaling_scale_in_cooldown_seconds       = var.autoscaling_scale_in_cooldown_seconds
  autoscaling_scale_out_cooldown_seconds      = var.autoscaling_scale_out_cooldown_seconds
}

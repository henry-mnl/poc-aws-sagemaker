data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix       = "${var.project_name}-${var.environment}"
  account_id        = data.aws_caller_identity.current.account_id
  region            = data.aws_region.current.id
  deploy_model      = var.model_artifact_s3_uri != ""
  deploy_gpu        = var.gpu_model_artifact_s3_uri != ""
  gpu_image         = var.gpu_container_image_uri != "" ? var.gpu_container_image_uri : var.container_image_uri
}

# ── S3 bucket ─────────────────────────────────────────────────────────────────
# Used for training input/output and model artifacts

resource "aws_s3_bucket" "sagemaker" {
  bucket        = "${local.name_prefix}-sagemaker-${local.account_id}"
  force_destroy = false
  tags          = var.tags
}

resource "aws_s3_bucket_versioning" "sagemaker" {
  bucket = aws_s3_bucket.sagemaker.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sagemaker" {
  bucket = aws_s3_bucket.sagemaker.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "sagemaker" {
  bucket = aws_s3_bucket.sagemaker.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Prefix placeholders so the bucket layout is self-documenting
resource "aws_s3_object" "training_input_prefix" {
  bucket  = aws_s3_bucket.sagemaker.id
  key     = "training/input/.keep"
  content = ""
  tags    = var.tags
}

resource "aws_s3_object" "training_output_prefix" {
  bucket  = aws_s3_bucket.sagemaker.id
  key     = "training/output/.keep"
  content = ""
  tags    = var.tags
}

resource "aws_s3_object" "models_prefix" {
  bucket  = aws_s3_bucket.sagemaker.id
  key     = "models/.keep"
  content = ""
  tags    = var.tags
}

# ── Security group ────────────────────────────────────────────────────────────

resource "aws_security_group" "sagemaker" {
  name        = "${local.name_prefix}-sagemaker-sg"
  description = "Security group attached to the SageMaker Studio domain and notebook instances"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

# Allow all outbound (required for downloading packages, calling AWS APIs)
resource "aws_vpc_security_group_egress_rule" "sagemaker_all_outbound" {
  security_group_id = aws_security_group.sagemaker.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"
}

# Allow intra-SG traffic so Studio apps can communicate with each other
resource "aws_vpc_security_group_ingress_rule" "sagemaker_self" {
  security_group_id            = aws_security_group.sagemaker.id
  referenced_security_group_id = aws_security_group.sagemaker.id
  ip_protocol                  = "-1"
  description                  = "Allow intra-domain SageMaker traffic"
}

# ── SageMaker Studio domain ───────────────────────────────────────────────────

resource "aws_sagemaker_domain" "this" {
  domain_name = var.domain_name
  auth_mode   = "IAM"
  vpc_id      = var.vpc_id
  subnet_ids  = var.subnet_ids

  default_user_settings {
    execution_role  = var.execution_role_arn
    security_groups = [aws_security_group.sagemaker.id]

    jupyter_server_app_settings {
      default_resource_spec {
        instance_type = "system"
      }
    }

    kernel_gateway_app_settings {
      default_resource_spec {
        instance_type = var.studio_kernel_instance_type
      }
    }
  }

  # Store domain EFS data in the SageMaker-managed EFS
  app_network_access_type = "VpcOnly"

  tags = var.tags
}

# ── SageMaker Studio user profiles (workspaces) ───────────────────────────────

resource "aws_sagemaker_user_profile" "data_scientist" {
  domain_id         = aws_sagemaker_domain.this.id
  user_profile_name = "${local.name_prefix}-data-scientist"

  user_settings {
    execution_role  = var.execution_role_arn
    security_groups = [aws_security_group.sagemaker.id]
  }

  tags = var.tags
}

resource "aws_sagemaker_user_profile" "ml_engineer" {
  domain_id         = aws_sagemaker_domain.this.id
  user_profile_name = "${local.name_prefix}-ml-engineer"

  user_settings {
    execution_role  = var.execution_role_arn
    security_groups = [aws_security_group.sagemaker.id]
  }

  tags = var.tags
}

resource "aws_sagemaker_user_profile" "devops" {
  domain_id         = aws_sagemaker_domain.this.id
  user_profile_name = "${local.name_prefix}-devops"

  user_settings {
    execution_role  = var.execution_role_arn
    security_groups = [aws_security_group.sagemaker.id]
  }

  tags = var.tags
}

# ── Notebook lifecycle configuration (spot training template) ─────────────────
# Provides a reusable lifecycle script that pre-configures the notebook
# environment and demonstrates how to launch a Managed Spot Training job.

resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "spot_training" {
  name = "${local.name_prefix}-spot-training-lc"

  # Runs every time the instance starts; installs helpers and writes a
  # sample spot-training launcher script to the notebook home directory.
  on_start = base64encode(templatefile("${path.module}/templates/notebook_on_start.sh.tftpl", {
    s3_bucket              = aws_s3_bucket.sagemaker.bucket
    training_role_arn      = var.training_role_arn
    training_instance_type = var.training_instance_type
    max_run_seconds        = var.training_max_run_seconds
    max_wait_seconds       = var.training_max_wait_seconds
    region                 = local.region
  }))
}

# ── SageMaker model (conditional on model artifact being available) ────────────

resource "aws_sagemaker_model" "this" {
  count = local.deploy_model ? 1 : 0

  name               = "${local.name_prefix}-model"
  execution_role_arn = var.inference_role_arn

  primary_container {
    image          = var.container_image_uri
    model_data_url = var.model_artifact_s3_uri
    mode           = "SingleModel"

    environment = {
      SAGEMAKER_PROGRAM          = "inference.py"
      SAGEMAKER_SUBMIT_DIRECTORY = "/opt/ml/code"
    }
  }

  tags = var.tags
}

# ── Endpoint configuration – on-demand instances ──────────────────────────────

resource "aws_sagemaker_endpoint_configuration" "this" {
  count = local.deploy_model ? 1 : 0

  name = "${local.name_prefix}-endpoint-config"

  production_variants {
    variant_name           = "primary"
    model_name             = aws_sagemaker_model.this[0].name
    initial_instance_count = var.endpoint_initial_instance_count
    instance_type          = var.endpoint_instance_type
  }

  tags = var.tags
}

# ── SageMaker inference endpoint ──────────────────────────────────────────────

resource "aws_sagemaker_endpoint" "this" {
  count = local.deploy_model ? 1 : 0

  name                 = "${local.name_prefix}-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.this[0].name

  tags = var.tags
}

# ── Application Auto Scaling ──────────────────────────────────────────────────
# Scales the number of on-demand instances behind the endpoint based on
# invocations per instance (target-tracking policy).

resource "aws_appautoscaling_target" "sagemaker_endpoint" {
  count = local.deploy_model ? 1 : 0

  resource_id        = "endpoint/${aws_sagemaker_endpoint.this[0].name}/variant/primary"
  scalable_dimension = "sagemaker:variant:DesiredInstanceCount"
  service_namespace  = "sagemaker"
  min_capacity       = var.endpoint_min_capacity
  max_capacity       = var.endpoint_max_capacity

  depends_on = [aws_sagemaker_endpoint.this]
}

resource "aws_appautoscaling_policy" "sagemaker_endpoint" {
  count = local.deploy_model ? 1 : 0

  name               = "${local.name_prefix}-endpoint-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.sagemaker_endpoint[0].resource_id
  scalable_dimension = aws_appautoscaling_target.sagemaker_endpoint[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.sagemaker_endpoint[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "SageMakerVariantInvocationsPerInstance"
    }

    target_value       = var.autoscaling_target_invocations_per_instance
    scale_in_cooldown  = var.autoscaling_scale_in_cooldown_seconds
    scale_out_cooldown = var.autoscaling_scale_out_cooldown_seconds
  }
}

# ── SageMaker training job (Managed Spot Training) ────────────────────────────
# This example job is created when a model artifact does NOT yet exist so it
# can be used as the initial training run.  When model_artifact_s3_uri is set,
# the assumption is that the model has already been trained and this resource
# is no longer needed (count = 0).

resource "aws_sagemaker_training_job" "spot" {
  count = local.deploy_model ? 0 : 1

  training_job_name = "${local.name_prefix}-spot-training-job"
  role_arn          = var.training_role_arn

  algorithm_specification {
    training_image      = var.container_image_uri
    training_input_mode = "File"
  }

  resource_config {
    instance_count    = 1
    instance_type     = var.training_instance_type
    volume_size_in_gb = var.training_volume_size_gb
  }

  # Managed Spot Training – use EC2 spot instances for cost savings
  enable_managed_spot_training = true

  stopping_condition {
    max_runtime_in_seconds   = var.training_max_run_seconds
    max_wait_time_in_seconds = var.training_max_wait_seconds
  }

  input_data_config {
    channel_name = "train"
    data_source {
      s3_data_source {
        s3_data_type              = "S3Prefix"
        s3_uri                    = "s3://${aws_s3_bucket.sagemaker.bucket}/training/input/"
        s3_data_distribution_type = "FullyReplicated"
      }
    }
    content_type     = "text/csv"
    compression_type = "None"
  }

  output_data_config {
    s3_output_path = "s3://${aws_s3_bucket.sagemaker.bucket}/training/output/"
  }

  tags = var.tags
}

# ── GPU endpoint with hardware-level isolation (NVIDIA MIG) ──────────────────
# Uses managed_instance_scaling (SageMaker-native) instead of Application Auto
# Scaling so the endpoint can participate in SageMaker's Inference Component
# model-placement algorithm on MIG-capable GPU instances (ml.p4de.24xlarge).
# The NVIDIA_MIG_CONFIG_DEVICES and CUDA_* environment variables instruct the
# NVIDIA Container Toolkit to expose individual MIG partitions as isolated
# compute contexts to each model container.

resource "aws_sagemaker_model" "gpu" {
  count = local.deploy_gpu ? 1 : 0

  name               = "${local.name_prefix}-gpu-model"
  execution_role_arn = var.inference_role_arn

  primary_container {
    image          = local.gpu_image
    model_data_url = var.gpu_model_artifact_s3_uri
    mode           = "SingleModel"

    environment = {
      SAGEMAKER_PROGRAM          = "inference.py"
      SAGEMAKER_SUBMIT_DIRECTORY = "/opt/ml/code"
      # NVIDIA MIG – expose all available MIG device partitions to the container
      NVIDIA_MIG_CONFIG_DEVICES  = "all"
      # NVIDIA MPS – shared GPU memory process service directories
      CUDA_MPS_PIPE_DIRECTORY    = "/tmp/nvidia-mps"
      CUDA_MPS_LOG_DIRECTORY     = "/tmp/nvidia-log"
    }
  }

  tags = var.tags
}

resource "aws_sagemaker_endpoint_configuration" "gpu" {
  count = local.deploy_gpu ? 1 : 0

  name = "${local.name_prefix}-gpu-endpoint-config"

  production_variants {
    variant_name = "gpu-primary"
    model_name   = aws_sagemaker_model.gpu[0].name
    # Start with a single instance; managed_instance_scaling will add more as
    # the workload grows – no separate aws_appautoscaling_* resources required.
    initial_instance_count = 1
    instance_type          = var.gpu_endpoint_instance_type

    managed_instance_scaling {
      status             = "ENABLED"
      min_instance_count = var.gpu_endpoint_min_capacity
      max_instance_count = var.gpu_endpoint_max_capacity
    }
  }

  tags = var.tags
}

resource "aws_sagemaker_endpoint" "gpu" {
  count = local.deploy_gpu ? 1 : 0

  name                 = "${local.name_prefix}-gpu-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.gpu[0].name

  tags = var.tags
}


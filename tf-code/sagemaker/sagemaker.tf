####################################################################################################
# Sagemaker Domain Configuration
####################################################################################################
resource "aws_sagemaker_domain" "sagemaker-domain" {
  domain_name             = var.domain_name
  auth_mode               = "SSO"
  vpc_id                  = var.vpc_id
  subnet_ids              = var.subnet_ids
  app_network_access_type = "VpcOnly"

  default_user_settings {
    execution_role    = var.execution_role_arn
    security_groups   = [aws_security_group.sagemaker-domain-sg.id]
    studio_web_portal = "Enabled"

    #TODO: Add applications settings based on requirement such as JupyterServer, RStudio, TensorBoard, etc.
  }
}

####################################################################################################
# Sagemaker Domain User Profiles
####################################################################################################
resource "aws_sagemaker_user_profile" "data_scientist" {
  domain_id         = aws_sagemaker_domain.sagemaker-domain.id
  user_profile_name = "${local.name_prefix}-data-scientist"

  user_settings {
    execution_role  = var.execution_role_arn
    security_groups = [aws_security_group.sagemaker-domain-sg.id]
  }
}

resource "aws_sagemaker_user_profile" "ml_engineer" {
  domain_id         = aws_sagemaker_domain.sagemaker-domain.id
  user_profile_name = "${local.name_prefix}-ml-engineer"

  user_settings {
    execution_role  = var.execution_role_arn
    security_groups = [aws_security_group.sagemaker-domain-sg.id]
  }
}

resource "aws_sagemaker_user_profile" "devops" {
  domain_id         = aws_sagemaker_domain.sagemaker-domain.id
  user_profile_name = "${local.name_prefix}-devops"

  user_settings {
    execution_role  = var.execution_role_arn
    security_groups = [aws_security_group.sagemaker-domain-sg.id]
  }
}

####################################################################################################
# Sagemaker Models
####################################################################################################
# get ecr uri of a prebuilt Sagemaker AI docker images
data "aws_sagemaker_prebuilt_ecr_image" "sagemaker-scikit-learn" {
  repository_name = "sagemaker-scikit-learn"
  image_tag       = "2.2-1.0.11.0"
}

# create a sagemaker model based on provided model artifact. Example use prebuilt Sagemaker AI docker image. Replace with appropriate ECR repo uri for other model
resource "aws_sagemaker_model" "model-1" {
  name               = "${local.name_prefix}-model"
  execution_role_arn = var.training_role_arn

  primary_container {
    image = data.aws_sagemaker_prebuilt_ecr_image.sagemaker-scikit-learn.registry_path
    mode  = "SingleModel" # change to MultiModel to load multiple models in the same container and load it into single instance.
    # model_data_url = "location of S3 model artifact, e.g. s3://${aws_s3_bucket.sagemaker-bucket.bucket}/model/model.tar.gz"


    # environment = {
    #   SAGEMAKER_PROGRAM          = "inference.py"
    #   SAGEMAKER_SUBMIT_DIRECTORY = "/opt/ml/code"
    # } # uncomment when needed to configure environment variable

    # image_config {
    #   repository_access_mode = "Vpc"
    # } # uncomment when using a custom ECR image in a private repository and need to pull image through VPC endpoint
  }
}

resource "aws_sagemaker_model" "model-mig" {
  name               = "${local.name_prefix}-model-mig"
  execution_role_arn = var.training_role_arn

  primary_container {
    image = data.aws_sagemaker_prebuilt_ecr_image.sagemaker-scikit-learn.registry_path
    mode  = "SingleModel" # change to MultiModel to load multiple models in the same container and load it into single instance.
    # model_data_url = "location of S3 model artifact, e.g. s3://${aws_s3_bucket.sagemaker-bucket.bucket}/model/model.tar.gz"

    environment = {
      SAGEMAKER_PROGRAM          = "inference.py"
      SAGEMAKER_SUBMIT_DIRECTORY = "/opt/ml/code"
      # NVIDIA MIG – expose all available MIG device partitions to the container
      NVIDIA_MIG_CONFIG_DEVICES = "all"
      # NVIDIA MPS – shared GPU memory process service directories
      CUDA_MPS_PIPE_DIRECTORY = "/tmp/nvidia-mps"
      CUDA_MPS_LOG_DIRECTORY  = "/tmp/nvidia-log"
    }

    # image_config {
    #   repository_access_mode = "Vpc"
    # } # uncomment when using a custom ECR image in a private repository and need to pull image through VPC endpoint
  }

}

####################################################################################################
# Sagemaker Notebook Instance Lifecycle Configuration
####################################################################################################
# Provides a reusable lifecycle script that pre-configures the notebook
# environment and demonstrates how to launch a Managed Spot Training job.

resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "spot_training" {
  name = "${local.name_prefix}-spot-training-lc"

  # Runs every time the instance starts; installs helpers and writes a
  # sample spot-training launcher script to the notebook home directory.
  on_start = base64encode(templatefile("${path.module}/templates/notebook_on_start.sh.tftpl", {
    s3_bucket              = aws_s3_bucket.sagemaker-bucket.id
    execution_role_arn     = var.training_role_arn
    training_instance_type = var.training_instance_type
    max_run_seconds        = var.training_max_run_seconds
    max_wait_seconds       = var.training_max_wait_seconds
    region                 = local.region
  }))
}

####################################################################################################
# Sagemaker Endpoints
####################################################################################################
# Create Sagemaker endpoint configuration using on-demand instances. For this POC, we'll use the model created above.
resource "aws_sagemaker_endpoint_configuration" "sagemaker-endpoint-config-primary" {
  name               = "${local.name_prefix}-endpoint-config-primary"
  execution_role_arn = var.inference_role_arn

  production_variants {
    variant_name           = "primary-variant"
    model_name             = aws_sagemaker_model.model-1.name
    initial_instance_count = var.endpoint_initial_instance_count # default to 1
    instance_type          = var.endpoint_instance_type          # default to ml.m5.large, adjust as needed based on your inference workload
  }
}

resource "aws_sagemaker_endpoint_configuration" "sagemaker-endpoint-config-mig" {
  name               = "${local.name_prefix}-endpoint-config-mig"
  execution_role_arn = var.inference_role_arn

  production_variants {
    variant_name           = "mig-variant" # create a mig-capable production variants
    model_name             = aws_sagemaker_model.model-mig.name
    initial_instance_count = var.endpoint_initial_instance_count # default to 1
    instance_type          = "ml.p4de.24xlarge"                  # 8× A100, MIG-capable

    managed_instance_scaling {
      status             = "DISABLED" # disable auto-scaling. Enable when needed. Using sagemaker managed auto-scaling so models will be distributed across available instances in the cluster, but won't scale up/down based on traffic. Adjust as needed based on your inference workload and scaling requirements.
      min_instance_count = 1
      max_instance_count = 2
    }
  }
}

resource "aws_sagemaker_endpoint" "endpoint-primary" {
  name                 = "${local.name_prefix}-endpoint-primary"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.sagemaker-endpoint-config-primary.name
}

resource "aws_sagemaker_endpoint" "endpoint-mig" {
  name                 = "${local.name_prefix}-endpoint-mig"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.sagemaker-endpoint-config-mig.name
}

# ── Application Auto Scaling ──────────────────────────────────────────────────
# Scales the number of on-demand instances behind the endpoint based on
# invocations per instance (target-tracking policy).

resource "aws_appautoscaling_target" "sagemaker_endpoint-primary" {
  resource_id        = "endpoint/${aws_sagemaker_endpoint.endpoint-primary[0].name}/variant/primary-variant"
  scalable_dimension = "sagemaker:variant:DesiredInstanceCount"
  service_namespace  = "sagemaker"
  min_capacity       = var.endpoint_min_capacity # default to 1, adjust as needed
  max_capacity       = var.endpoint_max_capacity # default to 4, adjust as needed

  depends_on = [aws_sagemaker_endpoint.endpoint-primary]
}

resource "aws_appautoscaling_policy" "sagemaker_endpoint-primary-scaling-policy" {
  name               = "${local.name_prefix}-endpoint-primary-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.sagemaker_endpoint-primary[0].resource_id
  scalable_dimension = aws_appautoscaling_target.sagemaker_endpoint-primary[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.sagemaker_endpoint-primary[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "SageMakerVariantInvocationsPerInstance"
    }

    target_value       = var.autoscaling_target_invocations_per_instance # default to 70, adjust as needed
    scale_in_cooldown  = var.autoscaling_scale_in_cooldown_seconds       # default to 300 seconds, adjust as needed
    scale_out_cooldown = var.autoscaling_scale_out_cooldown_seconds      # default to 60 seconds, adjust as needed
  }
}

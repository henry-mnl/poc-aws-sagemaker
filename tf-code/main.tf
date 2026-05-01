terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.28"
    }
  }
  required_version = ">= 1.1.0"
}

provider "aws" {
  region = "ap-southeast-1"

  default_tags {
    tags = {
      Name      = "Prod-AWS-3136-TF"
      ManagedBy = "Terraform"
    }
  }
}

locals {
  region      = data.aws_region.current.name
  name_prefix = "poc-ml-sagemaker"
}

module "sagemaker" {
  source = "./sagemaker"

  domain_name = "${local.name_prefix}-domain"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets

  # Spot training
  training_instance_type    = "ml.m5.xlarge"
  training_max_run_seconds  = 3600
  training_max_wait_seconds = 7200
  training_volume_size_gb   = 30

  # On-demand inference + autoscaling
  endpoint_instance_type                      = "ml.m5.large"
  endpoint_initial_instance_count             = 1
  endpoint_min_capacity                       = 1
  endpoint_max_capacity                       = 2
  autoscaling_target_invocations_per_instance = 100
  autoscaling_scale_in_cooldown_seconds       = 300
  autoscaling_scale_out_cooldown_seconds      = 300
}

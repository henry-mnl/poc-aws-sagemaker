locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ── SageMaker execution role ──────────────────────────────────────────────────

data "aws_iam_policy_document" "sagemaker_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sagemaker_execution" {
  name               = "${local.name_prefix}-sagemaker-execution"
  assume_role_policy = data.aws_iam_policy_document.sagemaker_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role       = aws_iam_role.sagemaker_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy_attachment" "sagemaker_s3_full_access" {
  role       = aws_iam_role.sagemaker_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "sagemaker_ecr_readonly" {
  role       = aws_iam_role.sagemaker_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ── Data Scientists ───────────────────────────────────────────────────────────

resource "aws_iam_group" "data_scientists" {
  name = "${local.name_prefix}-data-scientists"
  path = "/sagemaker/"
}

data "aws_iam_policy_document" "data_scientists" {
  # Studio / notebooks
  statement {
    sid    = "StudioAccess"
    effect = "Allow"
    actions = [
      "sagemaker:CreateDomain",
      "sagemaker:DescribeDomain",
      "sagemaker:ListDomains",
      "sagemaker:CreateUserProfile",
      "sagemaker:DescribeUserProfile",
      "sagemaker:ListUserProfiles",
      "sagemaker:CreateApp",
      "sagemaker:DeleteApp",
      "sagemaker:DescribeApp",
      "sagemaker:ListApps",
      "sagemaker:CreatePresignedDomainUrl",
      "sagemaker:CreateNotebookInstance",
      "sagemaker:DeleteNotebookInstance",
      "sagemaker:DescribeNotebookInstance",
      "sagemaker:StartNotebookInstance",
      "sagemaker:StopNotebookInstance",
      "sagemaker:UpdateNotebookInstance",
      "sagemaker:CreatePresignedNotebookInstanceUrl",
      "sagemaker:ListNotebookInstances",
      "sagemaker:CreateNotebookInstanceLifecycleConfig",
      "sagemaker:DescribeNotebookInstanceLifecycleConfig",
      "sagemaker:ListNotebookInstanceLifecycleConfigs",
    ]
    resources = ["*"]
  }

  # Training & experiments
  statement {
    sid    = "TrainingAccess"
    effect = "Allow"
    actions = [
      "sagemaker:CreateTrainingJob",
      "sagemaker:DescribeTrainingJob",
      "sagemaker:StopTrainingJob",
      "sagemaker:ListTrainingJobs",
      "sagemaker:CreateHyperParameterTuningJob",
      "sagemaker:DescribeHyperParameterTuningJob",
      "sagemaker:StopHyperParameterTuningJob",
      "sagemaker:ListHyperParameterTuningJobs",
      "sagemaker:CreateExperiment",
      "sagemaker:DescribeExperiment",
      "sagemaker:DeleteExperiment",
      "sagemaker:ListExperiments",
      "sagemaker:CreateTrial",
      "sagemaker:DescribeTrial",
      "sagemaker:ListTrials",
      "sagemaker:CreateTrialComponent",
      "sagemaker:DescribeTrialComponent",
      "sagemaker:ListTrialComponents",
      "sagemaker:AssociateTrialComponent",
    ]
    resources = ["*"]
  }

  # Pipelines
  statement {
    sid    = "PipelinesAccess"
    effect = "Allow"
    actions = [
      "sagemaker:CreatePipeline",
      "sagemaker:DescribePipeline",
      "sagemaker:UpdatePipeline",
      "sagemaker:DeletePipeline",
      "sagemaker:ListPipelines",
      "sagemaker:StartPipelineExecution",
      "sagemaker:StopPipelineExecution",
      "sagemaker:ListPipelineExecutions",
      "sagemaker:DescribePipelineExecution",
    ]
    resources = ["*"]
  }

  # Data access
  statement {
    sid    = "S3DataAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:CreateBucket",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECRReadAccess"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CloudWatchReadAccess"
    effect = "Allow"
    actions = [
      "logs:GetLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "PassRoleToSageMaker"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.sagemaker_execution.arn]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["sagemaker.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "data_scientists" {
  name        = "${local.name_prefix}-data-scientists-policy"
  description = "Permissions for Data Scientists to use SageMaker Studio, training jobs, and pipelines"
  policy      = data.aws_iam_policy_document.data_scientists.json
  tags        = var.tags
}

resource "aws_iam_group_policy_attachment" "data_scientists" {
  group      = aws_iam_group.data_scientists.name
  policy_arn = aws_iam_policy.data_scientists.arn
}

resource "aws_iam_group_membership" "data_scientists" {
  count = length(var.data_scientist_users) > 0 ? 1 : 0

  name  = "${local.name_prefix}-data-scientists-membership"
  group = aws_iam_group.data_scientists.name
  users = var.data_scientist_users
}

# ── ML Engineers ──────────────────────────────────────────────────────────────

resource "aws_iam_group" "ml_engineers" {
  name = "${local.name_prefix}-ml-engineers"
  path = "/sagemaker/"
}

data "aws_iam_policy_document" "ml_engineers" {
  # Full SageMaker access for model build/deploy cycles
  statement {
    sid       = "SageMakerFullAccess"
    effect    = "Allow"
    actions   = ["sagemaker:*"]
    resources = ["*"]
  }

  statement {
    sid       = "S3FullAccess"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }

  statement {
    sid       = "ECRFullAccess"
    effect    = "Allow"
    actions   = ["ecr:*"]
    resources = ["*"]
  }

  statement {
    sid    = "CloudWatchFullAccess"
    effect = "Allow"
    actions = [
      "logs:*",
      "cloudwatch:*",
    ]
    resources = ["*"]
  }

  # Autoscaling – engineers own endpoint scaling policies
  statement {
    sid       = "AutoScalingAccess"
    effect    = "Allow"
    actions   = ["application-autoscaling:*"]
    resources = ["*"]
  }

  statement {
    sid       = "PassRoleToSageMaker"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.sagemaker_execution.arn]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["sagemaker.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "ml_engineers" {
  name        = "${local.name_prefix}-ml-engineers-policy"
  description = "Permissions for ML Engineers to manage the full SageMaker model lifecycle"
  policy      = data.aws_iam_policy_document.ml_engineers.json
  tags        = var.tags
}

resource "aws_iam_group_policy_attachment" "ml_engineers" {
  group      = aws_iam_group.ml_engineers.name
  policy_arn = aws_iam_policy.ml_engineers.arn
}

resource "aws_iam_group_membership" "ml_engineers" {
  count = length(var.ml_engineer_users) > 0 ? 1 : 0

  name  = "${local.name_prefix}-ml-engineers-membership"
  group = aws_iam_group.ml_engineers.name
  users = var.ml_engineer_users
}

# ── DevOps ────────────────────────────────────────────────────────────────────

resource "aws_iam_group" "devops" {
  name = "${local.name_prefix}-devops"
  path = "/sagemaker/"
}

data "aws_iam_policy_document" "devops" {
  # Endpoint & model lifecycle
  statement {
    sid    = "SageMakerDeploymentAccess"
    effect = "Allow"
    actions = [
      "sagemaker:CreateModel",
      "sagemaker:DeleteModel",
      "sagemaker:DescribeModel",
      "sagemaker:ListModels",
      "sagemaker:CreateEndpointConfig",
      "sagemaker:DeleteEndpointConfig",
      "sagemaker:DescribeEndpointConfig",
      "sagemaker:ListEndpointConfigs",
      "sagemaker:CreateEndpoint",
      "sagemaker:UpdateEndpoint",
      "sagemaker:DeleteEndpoint",
      "sagemaker:DescribeEndpoint",
      "sagemaker:ListEndpoints",
      "sagemaker:UpdateEndpointWeightsAndCapacities",
      "sagemaker:InvokeEndpoint",
      "sagemaker:ListTags",
      "sagemaker:AddTags",
    ]
    resources = ["*"]
  }

  # Autoscaling management
  statement {
    sid    = "AutoScalingManagement"
    effect = "Allow"
    actions = [
      "application-autoscaling:RegisterScalableTarget",
      "application-autoscaling:DeregisterScalableTarget",
      "application-autoscaling:DescribeScalableTargets",
      "application-autoscaling:PutScalingPolicy",
      "application-autoscaling:DeleteScalingPolicy",
      "application-autoscaling:DescribeScalingPolicies",
      "application-autoscaling:DescribeScalingActivities",
    ]
    resources = ["*"]
  }

  # CloudWatch alarms used by auto-scaling
  statement {
    sid    = "CloudWatchAlarmManagement"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:DeleteAlarms",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
    ]
    resources = ["*"]
  }

  # IaC (CloudFormation / Terraform backend)
  statement {
    sid    = "CloudFormationAccess"
    effect = "Allow"
    actions = [
      "cloudformation:CreateStack",
      "cloudformation:UpdateStack",
      "cloudformation:DeleteStack",
      "cloudformation:DescribeStacks",
      "cloudformation:DescribeStackEvents",
      "cloudformation:GetTemplate",
      "cloudformation:ValidateTemplate",
      "cloudformation:ListStacks",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "IAMReadAccess"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:GetPolicy",
      "iam:ListRoles",
      "iam:ListPolicies",
      "iam:ListRolePolicies",
      "iam:GetRolePolicy",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "S3DeploymentAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "PassRoleToSageMaker"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.sagemaker_execution.arn]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["sagemaker.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "devops" {
  name        = "${local.name_prefix}-devops-policy"
  description = "Permissions for DevOps to manage SageMaker deployments, autoscaling, and infrastructure"
  policy      = data.aws_iam_policy_document.devops.json
  tags        = var.tags
}

resource "aws_iam_group_policy_attachment" "devops" {
  group      = aws_iam_group.devops.name
  policy_arn = aws_iam_policy.devops.arn
}

resource "aws_iam_group_membership" "devops" {
  count = length(var.devops_users) > 0 ? 1 : 0

  name  = "${local.name_prefix}-devops-membership"
  group = aws_iam_group.devops.name
  users = var.devops_users
}

####################################################################################################
# Devops Group - Full admin access to all AWS services except billing and IAM
####################################################################################################
resource "aws_iam_group" "devops-group" {
  name = "devops-group"
}

resource "aws_iam_policy" "full-admin-no-billing-policy" {
  name = "FullAdminNoBillingPolicy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "*",
        "Effect" : "Allow",
        "Resource" : "*",
        "Sid" : "FullAdminAccess"
      },
      {
        "Action" : [
          "aws-portal:*Billing",
          "aws-portal:*PaymentMethods",
          "aws-portal:*Usage",
          "billing:*",
          "budgets:*",
          "ce:*",
          "consolidatedbilling:*",
          "cur:*",
          "freetier:*",
          "invoicing:*",
          "payments:*",
          "pricing:DescribeServices",
          "purchase-orders:*",
          "sustainability:*",
          "tax:*",
        ],
        "Effect" : "Deny",
        "Resource" : "*",
        "Sid" : "DenyBillingAccess"
      },
      {
        "Action" : [
          "iam:Add*",
          "iam:CreateAccessKey",
          "iam:CreateAccountAlias",
          "iam:CreateGroup",
          "iam:CreateInstanceProfile",
          "iam:CreateLoginProfile",
          "iam:CreateOpenIDConnectProvider",
          "iam:CreatePolicy",
          "iam:CreatePolicyVersion",
          "iam:CreateRole",
          "iam:CreateSAMLProvider",
          "iam:CreateServiceSpecificCredential",
          "iam:CreateUser",
          "iam:Deactivate*",
          "iam:Delete*",
          "iam:Detach*",
          "iam:Put*",
          "iam:Remove*",
          "iam:Resync*",
          "iam:Set*",
          "iam:Simulate*",
          "iam:Update*",
          "iam:ListGroups",
          "iam:ListPolicies"
        ],
        "Effect" : "Deny",
        "Resource" : "*",
        "Sid" : "DenyIAMaccess"
      }
    ]
  })
}

####################################################################################################
# Data Scientists Group - Sagemaker Studio, read S3 bucket, submit training jobs
####################################################################################################
resource "aws_iam_group" "data-scientists-group" {
  name = "data-scientists-group"
}

resource "aws_iam_policy" "data-scientists-policy" {
  name = "data-scientists-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
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
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "TrainingAccess",
        "Effect" : "Allow",
        "Action" : [
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
        "Resource" : "*"
      },
      {
        "Sid" : "PipelinesAccess",
        "Effect" : "Allow",
        "Action" : [
          "sagemaker:DescribePipeline",
          "sagemaker:DescribePipelineExecution",
          "sagemaker:ListPipelines",
          "sagemaker:ListPipelineExecutions",
          "sagemaker:ListPipelineParametersForExecution",
          "sagemaker:DescribeModelPackage",
          "sagemaker:ListModelPackages",
          "sagemaker:DescribeModelPackageGroup",
          "sagemaker:ListModelPackageGroups",
        ]
        "Resource" : ["*"]
      },
      {
        "Sid" : "S3DataAccess",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
        ],
        "Resource" : "<input s3 bucket ARN here>" # replace with the ARN of the S3 bucket used for training data and model artifacts
      },
      {
        "Sid" : "ECRReadAccess",
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "CloudWatchReadAccess",
        "Effect" : "Allow",
        "Action" : [
          "logs:GetLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "PassRoleToSageMaker",
        "Effect" : "Allow",
        "Action" : ["iam:PassRole"],
        "Resource" : [
          "${aws_iam_role.sagemaker-training-role.arn}",
        ],
        "Condition" : {
          "StringEquals" : {
            "iam:PassedToService" : "sagemaker.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "data-scientists-policy-attachment" {
  group      = aws_iam_group.data-scientists-group.name
  policy_arn = aws_iam_policy.data-scientists-policy.arn
}

####################################################################################################
# ML Engineers Group - Manage Pipelines, Model Registry, Inference endpoints
####################################################################################################
resource "aws_iam_group" "ml-engineers-group" {
  name = "ml-engineers-group"
}

resource "aws_iam_policy" "ml-engineers-policy" {
  name = "ml-engineers-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "SageMakerFullAccess",
        "Effect" : "Allow",
        "Action" : ["sagemaker:*"],
        "Resource" : ["*"]
      },
      {
        "Sid" : "S3FullAccess",
        "Effect" : "Allow",
        "Action" : ["s3:*"],
        "Resource" : ["*"]
      },
      {
        "Sid" : "ECRFullAccess",
        "Effect" : "Allow",
        "Action" : ["ecr:*"],
        "Resource" : ["*"]
      },
      {
        "Sid" : "CloudWatchFullAccess",
        "Effect" : "Allow",
        "Action" : [
          "logs:*",
          "cloudwatch:*",
        ],
        "Resource" : ["*"]
      },
      {
        "Sid" : "AutoScalingAccess",
        "Effect" : "Allow",
        "Action" : ["application-autoscaling:*"],
        "Resource" : ["*"]
      },
      {
        "Sid" : "PassRoleToSageMakerForInferenceAndModelManagement",
        "Effect" : "Allow",
        "Action" : ["iam:PassRole"],
        "Resource" : [
          "${aws_iam_role.sagemaker-execution-role.arn}",
          "${aws_iam_role.sagemaker-inference-role.arn}",
        ],
        "Condition" : {
          "StringEquals" : {
            "iam:PassedToService" : "sagemaker.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "ml-engineers-policy-attachment" {
  group      = aws_iam_group.ml-engineers-group.name
  policy_arn = aws_iam_policy.ml-engineers-policy.arn
}

####################################################################################################
# Sagemaker Execution Role
####################################################################################################
resource "aws_iam_role" "sagemaker-execution-role" {
  name = "sagemaker-execution-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "sagemaker.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker-execution-role-policy-attachment-sagemaker-full-access" {
  role       = aws_iam_role.sagemaker-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy_attachment" "sagemaker-execution-role-policy-attachment-s3-full-access" {
  role       = aws_iam_role.sagemaker-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "sagemaker-execution-role-policy-attachment-ecr-read-only" {
  role       = aws_iam_role.sagemaker-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

####################################################################################################
# Sagemaker Training Role
####################################################################################################
resource "aws_iam_role" "sagemaker-training-role" {
  name = "sagemaker-training-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "sagemaker.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "sagemaker-training-role-policy" {
  name = "sagemaker-training-role-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*"
        ],
        "Resource" : "<input s3 bucket ARN here>" # replace with the ARN of the S3 bucket used for training data and model artifacts
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:*"
        ],
        "Resource" : "<input ECR repository ARN here>" # replace with the ARN of the ECR repository if using custom container images for training
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker-training-role-policy-attachment-sagemaker-full-access" {
  role       = aws_iam_role.sagemaker-training-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy_attachment" "sagemaker-training-role-policy-attachment-1" {
  role       = aws_iam_role.sagemaker-training-role.name
  policy_arn = aws_iam_policy.sagemaker-training-role-policy.arn
}

####################################################################################################
# Sagemaker Inference Role
####################################################################################################
resource "aws_iam_role" "sagemaker-inference-role" {
  name = "sagemaker-inference-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "sagemaker.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker-inference-role-policy-attachment-sagemaker-full-access" {
  role       = aws_iam_role.sagemaker-inference-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy_attachment" "sagemaker-inference-role-policy-attachment-s3-read-only" {
  role       = aws_iam_role.sagemaker-inference-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "sagemaker-inference-role-policy-attachment-ecr-read-only" {
  role       = aws_iam_role.sagemaker-inference-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

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

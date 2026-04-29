"""
Example: full model-registry workflow
======================================
This script demonstrates:
  1. Creating a Model Package Group (registry)
  2. Registering a model version
  3. Listing versions
  4. Approving the model
  5. Deploying the approved model to a real-time endpoint

Prerequisites
-------------
* AWS credentials configured (environment variables, ~/.aws/credentials, or
  an IAM role attached to the compute resource).
* Replace the placeholder values marked with <...> before running.
"""

import logging

from model_registry import ModelRegistry

logging.basicConfig(level=logging.INFO)

# ---------------------------------------------------------------------------
# Configuration – replace with your own values
# ---------------------------------------------------------------------------
REGION = "us-east-1"
ROLE_ARN = "<YOUR_SAGEMAKER_EXECUTION_ROLE_ARN>"
REGISTRY_NAME = "my-model-registry"
ENDPOINT_NAME = "my-model-endpoint"

ECR_IMAGE = "<YOUR_ECR_IMAGE_URI>"          # e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-image:latest
MODEL_DATA_URL = "<S3_URI_TO_MODEL_TAR_GZ>" # e.g. s3://my-bucket/model/model.tar.gz


def main() -> None:
    registry = ModelRegistry(
        model_package_group_name=REGISTRY_NAME,
        region=REGION,
    )

    # 1. Create the registry (idempotent – safe to run multiple times)
    registry.create_registry(
        description="POC model registry for SageMaker",
        tags=[{"Key": "Project", "Value": "poc-aws-sagemaker"}],
    )

    # 2. Register a model version
    inference_spec = {
        "Containers": [
            {
                "Image": ECR_IMAGE,
                "ModelDataUrl": MODEL_DATA_URL,
            }
        ],
        "SupportedTransformInstanceTypes": ["ml.m5.xlarge"],
        "SupportedRealtimeInferenceInstanceTypes": ["ml.m5.xlarge"],
        "SupportedContentTypes": ["text/csv"],
        "SupportedResponseMIMETypes": ["text/csv"],
    }

    register_response = registry.register_model(
        inference_spec=inference_spec,
        description="v1 - initial training run",
        tags=[{"Key": "Version", "Value": "1"}],
    )
    model_package_arn = register_response["ModelPackageArn"]
    print(f"Registered model: {model_package_arn}")

    # 3. List all pending versions
    pending = registry.list_model_versions(approval_status="PendingManualApproval")
    print(f"Pending versions: {len(pending)}")
    for v in pending:
        print(f"  {v['ModelPackageArn']}  status={v['ModelApprovalStatus']}")

    # 4. Approve the model
    registry.update_approval_status(
        model_package_arn=model_package_arn,
        approval_status="Approved",
        approval_description="Passed offline evaluation - promoting to production.",
    )
    print("Model approved.")

    # 5. Deploy the approved model
    endpoint_arn = registry.deploy(
        model_package_arn=model_package_arn,
        endpoint_name=ENDPOINT_NAME,
        instance_type="ml.m5.xlarge",
        instance_count=1,
        role_arn=ROLE_ARN,
        tags=[{"Key": "Project", "Value": "poc-aws-sagemaker"}],
    )
    print(f"Endpoint ARN: {endpoint_arn}")


if __name__ == "__main__":
    main()

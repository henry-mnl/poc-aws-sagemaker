# poc-aws-sagemaker

A proof-of-concept for the **AWS SageMaker Model Registry** - a central catalogue for versioning, approving, and deploying ML models.

---

## Repository layout

```
.
├── model_registry/          # Core Python package
│   ├── __init__.py
│   └── registry.py          # ModelRegistry class
├── examples/
│   └── full_workflow.py     # End-to-end usage example
├── requirements.txt
└── README.md
```

---

## Key concepts

| Concept | SageMaker resource | Description |
|---|---|---|
| **Registry** | `ModelPackageGroup` | Container for all versions of a model family |
| **Model version** | `ModelPackage` | A specific trained model artifact + metadata |
| **Approval status** | `ModelApprovalStatus` | `Approved` / `Rejected` / `PendingManualApproval` |
| **Deployment** | `Model` + `EndpointConfig` + `Endpoint` | Serve an approved version |

---

## Installation

```bash
pip install -r requirements.txt
```

---

## Quick start

```python
from model_registry import ModelRegistry

registry = ModelRegistry(
    model_package_group_name="my-model-registry",
    region="us-east-1",
)

# 1. Create the registry (idempotent)
registry.create_registry(description="My first model registry")

# 2. Register a new model version
resp = registry.register_model(
    inference_spec={
        "Containers": [{
            "Image": "<ECR_IMAGE_URI>",
            "ModelDataUrl": "s3://<bucket>/model.tar.gz",
        }],
        "SupportedTransformInstanceTypes": ["ml.m5.xlarge"],
        "SupportedRealtimeInferenceInstanceTypes": ["ml.m5.xlarge"],
        "SupportedContentTypes": ["text/csv"],
        "SupportedResponseMIMETypes": ["text/csv"],
    },
    description="Initial training run",
)
model_arn = resp["ModelPackageArn"]

# 3. Approve the model
registry.update_approval_status(model_arn, "Approved")

# 4. Deploy
registry.deploy(
    model_package_arn=model_arn,
    endpoint_name="my-endpoint",
    instance_type="ml.m5.xlarge",
    role_arn="<SAGEMAKER_EXECUTION_ROLE_ARN>",
)
```

See [`examples/full_workflow.py`](examples/full_workflow.py) for a complete walkthrough.

---

## API reference

### `ModelRegistry(model_package_group_name, region=None, boto_session=None)`

| Method | Description |
|---|---|
| `create_registry(description, tags)` | Create the Model Package Group (idempotent) |
| `describe_registry()` | Return group metadata |
| `delete_registry()` | Delete the group (all versions must be removed first) |
| `register_model(inference_spec, …)` | Register a new model version |
| `list_model_versions(approval_status, …)` | List versions with optional status filter |
| `describe_model_version(model_package_arn)` | Full metadata for one version |
| `update_approval_status(arn, status, …)` | Approve / Reject / reset to Pending |
| `delete_model_version(arn)` | Delete a single version |
| `deploy(arn, endpoint_name, instance_type, …)` | Deploy to a real-time endpoint |

---

## Required IAM permissions

The IAM role used must include at minimum:

```json
{
  "Effect": "Allow",
  "Action": [
    "sagemaker:CreateModelPackageGroup",
    "sagemaker:DescribeModelPackageGroup",
    "sagemaker:DeleteModelPackageGroup",
    "sagemaker:CreateModelPackage",
    "sagemaker:ListModelPackages",
    "sagemaker:DescribeModelPackage",
    "sagemaker:UpdateModelPackage",
    "sagemaker:DeleteModelPackage",
    "sagemaker:CreateModel",
    "sagemaker:CreateEndpointConfig",
    "sagemaker:CreateEndpoint",
    "sagemaker:UpdateEndpoint"
  ],
  "Resource": "*"
}
```
# poc-aws-sagemaker

Terraform code for an AWS SageMaker platform with:

- **SageMaker Studio Domain** (VPC-only mode) and **user-profile workspaces** for three personas
- **Managed Spot Training** job with configurable instance type, max-run / max-wait times, and S3 checkpointing
- **On-demand inference endpoint** with a target-tracking **auto-scaling policy** (`SageMakerVariantInvocationsPerInstance`)
- **IAM groups & policies** for Data Scientists, ML Engineers, and DevOps

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│  VPC                                                                  │
│                                                                       │
│  ┌──────────────────────────────┐   ┌───────────────────────────┐   │
│  │  SageMaker Studio Domain     │   │  SageMaker Endpoint        │   │
│  │  (auth_mode = IAM, VPC-only) │   │  (on-demand instances)     │   │
│  │                              │   │  ↕ AppAutoScaling          │   │
│  │  User Profiles               │   │    (target-tracking)       │   │
│  │  • data-scientist            │   └───────────────────────────┘   │
│  │  • ml-engineer               │                                    │
│  │  • devops                    │   ┌───────────────────────────┐   │
│  └──────────────────────────────┘   │  Spot Training Job         │   │
│                                     │  (Managed Spot Training)   │   │
│  ┌──────────────────────────────┐   │  • S3 checkpointing        │   │
│  │  S3 Bucket (encrypted)       │   └───────────────────────────┘   │
│  │  training/input/             │                                    │
│  │  training/output/            │                                    │
│  │  training/checkpoints/       │                                    │
│  │  models/                     │                                    │
│  └──────────────────────────────┘                                    │
└──────────────────────────────────────────────────────────────────────┘

IAM
  • SageMaker execution role (assumed by sagemaker.amazonaws.com)
  • Group: data-scientists   – Studio / training / pipeline access
  • Group: ml-engineers      – Full SageMaker + ECR + autoscaling
  • Group: devops            – Endpoint management + CF + autoscaling
```

---

## Module structure

```
.
├── main.tf           # root module – wires iam + sagemaker modules together
├── variables.tf
├── outputs.tf
├── versions.tf
└── modules/
    ├── iam/
    │   ├── main.tf   # execution role, three IAM groups and policies
    │   ├── variables.tf
    │   └── outputs.tf
    └── sagemaker/
        ├── main.tf   # domain, user profiles, S3, training job, endpoint, autoscaling
        ├── variables.tf
        ├── outputs.tf
        └── templates/
            └── notebook_on_start.sh.tftpl  # lifecycle script with spot-training example
```

---

## Prerequisites

| Tool | Minimum version |
|------|----------------|
| Terraform | 1.3.0 |
| AWS provider | 5.0.0 |
| AWS CLI | 2.x (for `terraform init`) |

An existing **VPC** with **private subnets** is required.

---

## Quick start

### 1. Create a `terraform.tfvars` file (excluded from version control)

```hcl
aws_region   = "us-east-1"
project_name = "poc-sagemaker"
environment  = "dev"

vpc_id     = "vpc-0123456789abcdef0"
subnet_ids = ["subnet-aaa", "subnet-bbb"]

# Optional – add IAM users to the groups
data_scientist_users = ["alice", "bob"]
ml_engineer_users    = ["charlie"]
devops_users         = ["dave"]

# Set this after your first training job to create the endpoint
# model_artifact_s3_uri = "s3://poc-sagemaker-dev-sagemaker-<account>/training/output/<job>/output/model.tar.gz"
```

### 2. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 3. Spot training workflow

1. Upload your training CSV to `s3://<bucket>/training/input/`
2. `terraform apply` with `model_artifact_s3_uri = ""` (default) – this creates a `aws_sagemaker_training_job` with **Managed Spot Training** enabled.
3. Once the job completes, copy the model artifact URI from the console or:
   ```bash
   aws sagemaker describe-training-job \
     --training-job-name poc-sagemaker-dev-spot-training-job \
     --query 'ModelArtifacts.S3ModelArtifacts'
   ```
4. Set `model_artifact_s3_uri` in your `.tfvars` and re-run `terraform apply`.  
   This creates the **Model → EndpointConfig → Endpoint** resources and the autoscaling policy.

### 4. Access Studio

```bash
aws sagemaker create-presigned-domain-url \
  --domain-id <domain_id> \
  --user-profile-name poc-sagemaker-dev-data-scientist
```

---

## IAM groups summary

| Group | Key permissions |
|-------|----------------|
| `data-scientists` | Studio, notebook instances, training jobs, hyperparameter tuning, pipelines, experiments, S3 read/write |
| `ml-engineers` | Full SageMaker + S3 + ECR + CloudWatch + ApplicationAutoScaling |
| `devops` | Endpoint lifecycle, autoscaling management, CloudWatch alarms, CloudFormation, IAM read |

---

## Inputs

See [`variables.tf`](variables.tf) for the full list of input variables and their defaults.

## Outputs

| Name | Description |
|------|-------------|
| `sagemaker_domain_id` | SageMaker Studio domain ID |
| `sagemaker_domain_url` | SageMaker Studio domain URL |
| `sagemaker_s3_bucket` | S3 bucket name for training data and artifacts |
| `sagemaker_training_job_name` | Spot training job name (when `model_artifact_s3_uri` is empty) |
| `sagemaker_endpoint_name` | Inference endpoint name (when `model_artifact_s3_uri` is set) |
| `sagemaker_execution_role_arn` | ARN of the SageMaker execution role |
| `data_scientists_group_name` | IAM group name – Data Scientists |
| `ml_engineers_group_name` | IAM group name – ML Engineers |
| `devops_group_name` | IAM group name – DevOps |
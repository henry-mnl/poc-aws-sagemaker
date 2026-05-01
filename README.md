# poc-aws-sagemaker

To run the terraform, run from inside the tf-code folder

This terraform will create and deploy the following resources :
1. VPC
   - Using AWS VPC Terraform Module as the base
   - The code will deploy VPC with private subnets only, without NAT Gateway and Internet Gateway
   - Commented-out codes, and options are still presented in code to provide option to adjust further
2. VPC Endpoints
   - Create VPC Endpoints to provide connection since the VPC is deployed without any internet connection
   - Created endpoints for S3, ECR, Sagemaker, Bedrock, Cloudwatch, Monitoring, STS
   - Associated Interface-type VPC Endpoint with Security Group with permissive ingress and egress rules. This is to reduce overhead of needing to add new rules when creating new apps, but can be scoped when needed for better security
3. IAM Groups, Policy
    - Created 3 Groups. Devops, Data Scientist, ML Engineers
    - Devops will have full AWS Account admin capability, however will not have IAM permissions like creating new users and billing
    - Data Scientist will have Sagemaker Studio Access, access to necessary S3, and submit training jobs inside sagemaker
    - ML Engineers will have full access to Sagemaker, S3, Cloudwatch, and ECR. They will be managing the Sagemaker domain, manage pipelines, model registry, and inference deployment
    - Will be connected to the available identity solution
4. Sagemaker Domain
   - Create a Sagemaker domain, with Vpc-Only access
   - Create 3 base user profile for the Sagemaker domain. Data Scientist, ML Engineer and Devops
   - For purpose of the POC, the tf-code will create a Sagemaker model based on publicly-available image
   - Created a notebook lifecycle config. This will inject a bash script that will make sure when running notebook instances, it will use Spot-instances instead of On-demand.
   - Created 2 endpoints. 1 with auto-scaling enabled based on invocation activity and linked to Cloudwatch, another with NVIDIA MIG-capable instances with managed by AWS Sagemaker itself 

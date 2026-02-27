# GreptimeDB Terraform (AWS S3 + IRSA)

This Terraform project creates AWS resources required for GreptimeDB object storage access from EKS via IRSA.

## What it creates
- S3 bucket for GreptimeDB object storage
- IAM policy with bucket/object permissions for that bucket
- IAM role with OIDC trust policy for a Kubernetes service account
- IAM policy attachment to the role

## Requirements
- Terraform `>= 1.5.0`
- AWS provider `>= 5.0`
- AWS credentials configured in your environment

## Inputs
Required:
- `aws_region`
- `bucket_name`
- `eks_oidc_provider_id`
- `k8s_service_account_namespace`
- `k8s_service_account_name`

Optional:
- `bucket_size_gb` (default: `100`, informational tag only)
- `iam_policy_name` (default: `mdai-greptime-s3-policy`)
- `iam_role_name` (default: `mdai-greptime-irsa-role`)
- `aws_account_id` (default: `null`, auto-resolved from current AWS caller identity)

## Outputs
- `bucket_name`
- `bucket_arn`
- `iam_policy_arn`
- `iam_role_arn`
- `effective_aws_account_id`

## Usage
```bash
# Do not run terraform inside Helm chart directory! Copy it over somewhere!
cp -r greptimedb/terraform /somewhere
cd /somewhere
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

## Example tfvars
```hcl
aws_region                    = "us-east-2"
bucket_name                   = "mdai-greptime-object-storage"
bucket_size_gb                = 100
iam_policy_name               = "mdai-greptime-s3-policy"
iam_role_name                 = "mdai-greptime-irsa-role"
# aws_account_id              = "123456789012" # optional
eks_oidc_provider_id          = "3B3EC4E13EF381458A69207C78AC56EC"
k8s_service_account_namespace = "mdai"
k8s_service_account_name      = "greptimedb-standalone"
```

## Notes
- S3 does not support hard bucket size limits; `bucket_size_gb` is recorded as a tag.
- After apply, annotate your Kubernetes service account with `iam_role_arn`.

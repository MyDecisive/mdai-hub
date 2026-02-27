variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket to create."
  type        = string
}

variable "bucket_size_gb" {
  description = "Desired bucket size in GB (informational only; S3 has no hard per-bucket size limit)."
  type        = number
  default     = 100
}

variable "iam_policy_name" {
  description = "Name of IAM policy for S3 access."
  type        = string
  default     = "mdai-greptime-s3-policy"
}

variable "iam_role_name" {
  description = "Name of IAM role for EKS service account access."
  type        = string
  default     = "mdai-greptime-irsa-role"
}

variable "aws_account_id" {
  description = "AWS account ID for trust policy. If null, use current caller account ID."
  type        = string
  default     = null
}

variable "eks_oidc_provider_id" {
  description = "EKS OIDC provider ID (last segment after /id/)."
  type        = string
}

variable "k8s_service_account_namespace" {
  description = "Kubernetes namespace of the service account."
  type        = string
}

variable "k8s_service_account_name" {
  description = "Kubernetes service account name."
  type        = string
}

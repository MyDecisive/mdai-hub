data "aws_caller_identity" "current" {}

locals {
  effective_aws_account_id = coalesce(var.aws_account_id, data.aws_caller_identity.current.account_id)

  oidc_provider_hostpath = "oidc.eks.${var.aws_region}.amazonaws.com/id/${var.eks_oidc_provider_id}"
  service_account_sub    = "system:serviceaccount:${var.k8s_service_account_namespace}:${var.k8s_service_account_name}"
}

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  tags = {
    Name          = var.bucket_name
    intended_size = "${var.bucket_size_gb}GB"
    managed_by    = "terraform"
  }
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    sid     = "ListBucket"
    effect  = "Allow"
    actions = ["s3:ListBucket"]

    resources = [aws_s3_bucket.this.arn]
  }

  statement {
    sid    = "ObjectRW"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:ListMultipartUploadParts",
      "s3:ListBucketMultipartUploads",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload"
    ]

    resources = ["${aws_s3_bucket.this.arn}/*"]
  }
}

resource "aws_iam_policy" "this" {
  name   = var.iam_policy_name
  policy = data.aws_iam_policy_document.s3_access.json
}

data "aws_iam_policy_document" "irsa_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${local.effective_aws_account_id}:oidc-provider/${local.oidc_provider_hostpath}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_hostpath}:sub"
      values   = [local.service_account_sub]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.irsa_trust.json
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

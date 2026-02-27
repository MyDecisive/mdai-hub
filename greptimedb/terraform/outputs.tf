output "bucket_name" {
  value = aws_s3_bucket.this.id
}

output "bucket_arn" {
  value = aws_s3_bucket.this.arn
}

output "iam_policy_arn" {
  value = aws_iam_policy.this.arn
}

output "iam_role_arn" {
  value = aws_iam_role.this.arn
}

output "effective_aws_account_id" {
  value = local.effective_aws_account_id
}

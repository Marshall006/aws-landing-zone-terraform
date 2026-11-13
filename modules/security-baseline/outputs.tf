output "audit_bucket" {
  value = aws_s3_bucket.audit.id
}

output "cloudtrail_arn" {
  value = aws_cloudtrail.audit.arn
}

output "audit_kms_key_arn" {
  value = aws_kms_key.audit.arn
}

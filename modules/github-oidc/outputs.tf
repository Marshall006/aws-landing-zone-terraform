output "plan_role_arn" {
  description = "À enregistrer comme variable GitHub AWS_PLAN_ROLE_ARN."
  value       = aws_iam_role.this["plan"].arn
}

output "apply_role_arn" {
  description = "À enregistrer comme variable GitHub AWS_APPLY_ROLE_ARN."
  value       = aws_iam_role.this["apply"].arn
}

output "github_plan_role_arn" {
  value = module.github_oidc.plan_role_arn
}

output "github_apply_role_arn" {
  value = module.github_oidc.apply_role_arn
}

output "cloudtrail_arn" {
  value = module.security.cloudtrail_arn
}

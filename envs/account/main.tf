# =============================================================================
# Socle du COMPTE (déployé une seule fois) : sécurité, accès CI, budgets.
# Les réseaux des environnements dev et prod s'appuient dessus.
# =============================================================================

module "security" {
  source             = "../../modules/security-baseline"
  name               = "landing-zone"
  log_retention_days = 365
  enable_guardduty   = var.enable_guardduty
}

module "github_oidc" {
  source            = "../../modules/github-oidc"
  github_repository = "Marshall006/aws-landing-zone-terraform"
  state_bucket      = var.state_bucket
}

module "finops" {
  source             = "../../modules/finops"
  name               = "landing-zone"
  monthly_budget_usd = var.monthly_budget_usd
  alert_emails       = var.alert_emails
}

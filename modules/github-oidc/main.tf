# =============================================================================
# Accès de GitHub Actions à AWS SANS clé d'accès (OIDC)
#
# Au lieu de stocker une clé AWS permanente dans GitHub (qui peut fuiter),
# chaque exécution de workflow présente un jeton signé par GitHub décrivant
# QUI elle est (dépôt, branche, environnement). AWS l'échange contre des
# identifiants temporaires (1 h), seulement si le jeton correspond.
#
#   plan  : lecture seule, pour toute pull request du dépôt
#   apply : droits d'administration, UNIQUEMENT depuis l'environnement
#           GitHub protégé (approbation humaine obligatoire)
# =============================================================================

data "aws_partition" "current" {}

locals {
  oidc_host        = "token.actions.githubusercontent.com"
  state_bucket_arn = "arn:${data.aws_partition.current.partition}:s3:::${var.state_bucket}"

  trust = {
    plan = [
      "repo:${var.github_repository}:pull_request",
      "repo:${var.github_repository}:ref:refs/heads/main",
    ]
    apply = ["repo:${var.github_repository}:environment:${var.apply_environment}"]
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://${local.oidc_host}"
  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "this" {
  for_each             = local.trust
  name                 = "github-terraform-${each.key}"
  max_session_duration = 3600
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "${local.oidc_host}:aud" = "sts.amazonaws.com" }
        # Le « sub » identifie précisément le dépôt et la branche / l'environnement
        StringLike = { "${local.oidc_host}:sub" = each.value }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "plan_read_only" {
  role       = aws_iam_role.this["plan"].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "apply_admin" {
  role       = aws_iam_role.this["apply"].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AdministratorAccess"
}

# Le rôle « plan » doit pouvoir lire l'état et poser le verrou (fichier .tflock)
resource "aws_iam_role_policy" "state_access" {
  for_each = aws_iam_role.this
  name     = "terraform-state"
  role     = each.value.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = local.state_bucket_arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${local.state_bucket_arn}/*"
      },
    ]
  })
}

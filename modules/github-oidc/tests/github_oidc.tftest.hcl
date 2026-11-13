mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_resource "aws_iam_openid_connect_provider" {
    defaults = {
      arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
    }
  }
}

variables {
  github_repository = "Marshall006/aws-landing-zone-terraform"
  state_bucket      = "tfstate-123456789012-eu-west-3"
}

run "no_static_keys_and_audience_is_sts" {
  command = apply

  assert {
    condition     = aws_iam_openid_connect_provider.github.url == "https://token.actions.githubusercontent.com"
    error_message = "Le fournisseur d'identité doit être celui de GitHub Actions."
  }
  assert {
    condition = alltrue([
      for r in aws_iam_role.this :
      jsondecode(r.assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:aud"] == "sts.amazonaws.com"
    ])
    error_message = "Chaque rôle doit vérifier l'audience du jeton."
  }
}

run "apply_role_requires_protected_environment" {
  command = apply

  assert {
    condition = jsondecode(aws_iam_role.this["apply"].assume_role_policy).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"] == [
      "repo:Marshall006/aws-landing-zone-terraform:environment:production"
    ]
    error_message = "Seul l'environnement GitHub protégé peut obtenir le rôle d'administration."
  }
}

run "plan_role_is_read_only_and_scoped_to_the_repository" {
  command = apply

  assert {
    condition     = aws_iam_role_policy_attachment.plan_read_only.policy_arn == "arn:aws:iam::aws:policy/ReadOnlyAccess"
    error_message = "Le rôle plan doit être en lecture seule."
  }
  assert {
    condition = alltrue([
      for sub in jsondecode(aws_iam_role.this["plan"].assume_role_policy).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"] :
      startswith(sub, "repo:Marshall006/aws-landing-zone-terraform:")
    ])
    error_message = "Aucun autre dépôt ne doit pouvoir assumer le rôle."
  }
}

run "rejects_wildcard_repository" {
  command = plan
  variables {
    github_repository = "*"
  }
  expect_failures = [var.github_repository]
}

mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "123456789012" }
  }
  mock_data "aws_region" {
    defaults = { region = "eu-west-3" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  # ARN réalistes : le fournisseur AWS valide le format des ARN
  mock_resource "aws_kms_key" {
    defaults = {
      arn    = "arn:aws:kms:eu-west-3:123456789012:key/11111111-2222-3333-4444-555555555555"
      key_id = "11111111-2222-3333-4444-555555555555"
    }
  }
  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::acme-audit-logs-123456789012-eu-west-3"
    }
  }
}

variables {
  name = "acme"
}

run "cloudtrail_is_complete_and_tamper_evident" {
  command = apply

  assert {
    condition     = aws_cloudtrail.audit.is_multi_region_trail && aws_cloudtrail.audit.include_global_service_events
    error_message = "CloudTrail doit couvrir toutes les régions et les services globaux (IAM)."
  }
  assert {
    condition     = aws_cloudtrail.audit.enable_log_file_validation
    error_message = "La validation d'intégrité des journaux doit être activée."
  }
}

run "audit_logs_are_private_encrypted_and_tls_only" {
  command = apply

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.audit.block_public_acls,
      aws_s3_bucket_public_access_block.audit.block_public_policy,
      aws_s3_bucket_public_access_block.audit.restrict_public_buckets,
    ])
    error_message = "Le bucket d'audit ne doit jamais être public."
  }
  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.audit.rule).apply_server_side_encryption_by_default).sse_algorithm == "aws:kms"
    error_message = "Les journaux doivent être chiffrés avec KMS."
  }
  assert {
    condition     = aws_kms_key.audit.enable_key_rotation
    error_message = "La rotation de la clé KMS doit être activée."
  }
  assert {
    condition     = jsondecode(aws_s3_bucket_policy.audit.policy).Statement[0].Condition.Bool["aws:SecureTransport"] == "false"
    error_message = "Le bucket doit refuser tout accès non chiffré (HTTP)."
  }
  assert {
    condition     = aws_s3_bucket.audit.bucket == "acme-audit-logs-123456789012-eu-west-3"
    error_message = "Nom de bucket inattendu (doit être unique par compte et par région)."
  }
}

run "account_guardrails" {
  command = apply

  assert {
    condition     = aws_s3_account_public_access_block.this.block_public_policy
    error_message = "Le blocage des accès publics S3 doit s'appliquer à tout le compte."
  }
  assert {
    condition     = aws_ebs_encryption_by_default.this.enabled
    error_message = "Les disques EBS doivent être chiffrés par défaut."
  }
  assert {
    condition     = aws_iam_account_password_policy.this.minimum_password_length >= 14
    error_message = "Mots de passe IAM : 14 caractères minimum."
  }
  assert {
    condition     = length(aws_guardduty_detector.this) == 0
    error_message = "GuardDuty (payant) doit être désactivé par défaut."
  }
}

run "guardduty_can_be_enabled" {
  command = apply
  variables {
    enable_guardduty = true
  }
  assert {
    condition     = length(aws_guardduty_detector.this) == 1
    error_message = "GuardDuty doit pouvoir être activé."
  }
}

run "rejects_short_log_retention" {
  command = plan
  variables {
    log_retention_days = 30
  }
  expect_failures = [var.log_retention_days]
}

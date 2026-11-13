# =============================================================================
# Amorçage : le bucket S3 qui stockera l'ÉTAT Terraform de tous les
# environnements (à exécuter une seule fois, avec un état local).
#
# L'état Terraform est la « mémoire » de ce qui a été créé. Il doit être :
#   - partagé (travail en équipe, CI)        -> S3
#   - verrouillé pendant un changement        -> fichier .tflock natif S3
#                                                (DynamoDB n'est plus nécessaire
#                                                 depuis Terraform 1.10)
#   - historisé (retour arrière possible)     -> versioning
#   - chiffré et privé                        -> SSE + blocage public + TLS
# =============================================================================
terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "region" {
  type    = string
  default = "eu-west-3" # Paris
}

provider "aws" {
  region = var.region
  default_tags {
    tags = { Project = "landing-zone", ManagedBy = "terraform", Component = "bootstrap" }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "state" {
  bucket = "tfstate-${data.aws_caller_identity.current.account_id}-${var.region}"
  lifecycle {
    prevent_destroy = true # supprimer l'état par erreur serait catastrophique
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    id     = "expire-old-versions"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [aws_s3_bucket.state.arn, "${aws_s3_bucket.state.arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
}

output "backend_config" {
  description = "Contenu à copier dans envs/backend.hcl"
  value       = <<-EOT
    bucket = "${aws_s3_bucket.state.id}"
    region = "${var.region}"
  EOT
}

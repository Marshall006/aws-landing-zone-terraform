terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  # bucket et region : terraform init -backend-config=../backend.hcl
  backend "s3" {
    key          = "dev/terraform.tfstate"
    use_lockfile = true # verrou natif S3 (Terraform >= 1.10)
    encrypt      = true
  }
}

provider "aws" {
  region = var.region
  # Étiquettes appliquées à TOUTES les ressources : indispensables pour savoir
  # qui dépense quoi (FinOps) et qui est responsable de quoi.
  default_tags {
    tags = {
      Project     = "landing-zone"
      Environment = "dev"
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
      Repository  = "github.com/Marshall006/aws-landing-zone-terraform"
    }
  }
}

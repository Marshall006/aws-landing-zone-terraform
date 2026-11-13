variable "github_repository" {
  description = "Dépôt autorisé à déployer, au format propriétaire/dépôt."
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "Format attendu : propriétaire/dépôt."
  }
}

variable "state_bucket" {
  description = "Bucket S3 de l'état Terraform (lecture/écriture pour les deux rôles)."
  type        = string
}

variable "apply_environment" {
  description = <<-EOT
    Environnement GitHub autorisé à appliquer les changements. En le protégeant
    par une approbation obligatoire (Settings > Environments), aucun « apply »
    ne peut avoir lieu sans validation humaine.
  EOT
  type        = string
  default     = "production"
}

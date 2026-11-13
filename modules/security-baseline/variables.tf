variable "name" {
  description = "Préfixe des noms de ressources."
  type        = string
}

variable "log_retention_days" {
  description = "Conservation des journaux d'audit CloudTrail dans S3 (jours)."
  type        = number
  default     = 365
  validation {
    condition     = var.log_retention_days >= 90
    error_message = "Conserver au moins 90 jours de journaux d'audit."
  }
}

variable "enable_guardduty" {
  description = "Détection de menaces GuardDuty (payante après 30 jours d'essai)."
  type        = bool
  default     = false
}

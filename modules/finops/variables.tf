variable "name" {
  description = "Préfixe des noms de ressources."
  type        = string
}

variable "monthly_budget_usd" {
  description = "Budget mensuel (USD) du compte."
  type        = number
  validation {
    condition     = var.monthly_budget_usd > 0
    error_message = "Le budget doit être positif."
  }
}

variable "alert_emails" {
  description = "Adresses qui reçoivent les alertes de dépenses."
  type        = list(string)
  validation {
    condition     = length(var.alert_emails) > 0 && alltrue([for e in var.alert_emails : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", e))])
    error_message = "Au moins une adresse e-mail valide est requise."
  }
}

variable "actual_thresholds_percent" {
  description = "Seuils d'alerte sur la dépense RÉELLE (% du budget)."
  type        = list(number)
  default     = [50, 80, 100]
}

variable "enable_anomaly_detection" {
  description = <<-EOT
    Détection d'anomalies de coûts (Cost Anomaly Detection, gratuite).
    AWS limite le nombre de moniteurs « services » par compte : désactiver si
    le moniteur par défaut existe déjà.
  EOT
  type        = bool
  default     = true
}

variable "anomaly_threshold_usd" {
  description = "Impact minimal (USD) d'une anomalie pour déclencher une alerte."
  type        = number
  default     = 10
}

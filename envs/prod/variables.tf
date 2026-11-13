variable "region" {
  description = "Région AWS (Paris par défaut, la plus proche de l'Afrique de l'Ouest francophone parmi les régions standard)."
  type        = string
  default     = "eu-west-3"
}

variable "owner" {
  description = "Responsable des ressources (étiquette Owner)."
  type        = string
  default     = "soumaila.idani"
}

variable "cost_center" {
  description = "Centre de coût (étiquette CostCenter)."
  type        = string
  default     = "portfolio"
}

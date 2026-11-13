variable "name" {
  description = "Préfixe des noms de ressources (ex. « dev »)."
  type        = string
}

variable "cidr" {
  description = "Plage d'adresses IP du VPC (ex. 10.10.0.0/16)."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.cidr)) && tonumber(split("/", var.cidr)[1]) <= 20
    error_message = "Le CIDR doit être valide et au moins aussi large qu'un /20."
  }
}

variable "az_count" {
  description = "Nombre de zones de disponibilité (2 minimum pour la haute disponibilité)."
  type        = number
  default     = 2
  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count doit valoir 2 ou 3."
  }
}

variable "nat_mode" {
  description = <<-EOT
    Accès Internet sortant des sous-réseaux privés :
      none   : aucun (0 $/mois)          -> dev, ou workloads sans Internet
      single : 1 NAT Gateway partagée    -> ~33 $/mois, point de défaillance unique
      per_az : 1 NAT Gateway par zone    -> ~33 $/mois x zones, haute disponibilité
  EOT
  type        = string
  default     = "none"
  validation {
    condition     = contains(["none", "single", "per_az"], var.nat_mode)
    error_message = "nat_mode doit valoir none, single ou per_az."
  }
}

variable "flow_logs_retention_days" {
  description = "Durée de conservation des journaux de flux réseau."
  type        = number
  default     = 30
}

# Environnement « prod » : 1 NAT Gateway (accès Internet sortant), journaux 30 jours.
# Pour une haute disponibilité totale : nat_mode = "per_az" (une NAT par zone).
module "network" {
  source                   = "../../modules/network"
  name                     = "prod"
  cidr                     = "10.20.0.0/16"
  az_count                 = 2
  nat_mode                 = "single"
  flow_logs_retention_days = 30
}

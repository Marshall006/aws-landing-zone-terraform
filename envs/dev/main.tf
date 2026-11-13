# Environnement « dev » : coût minimal (aucune NAT Gateway, journaux 7 jours)
module "network" {
  source                   = "../../modules/network"
  name                     = "dev"
  cidr                     = "10.10.0.0/16"
  az_count                 = 2
  nat_mode                 = "none"
  flow_logs_retention_days = 7
}

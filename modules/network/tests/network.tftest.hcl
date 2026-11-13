# Tests unitaires du module réseau : aucun compte AWS nécessaire.
# « apply » est ici entièrement simulé : aucune ressource réelle n'est créée.
# Le fournisseur AWS est simulé (« mock ») : Terraform calcule le plan et on
# vérifie nos règles d'architecture.

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
    }
  }
  mock_data "aws_region" {
    defaults = {
      region = "eu-west-3"
    }
  }
  # Sans ces valeurs, le simulateur générerait des chaînes aléatoires que le
  # fournisseur AWS refuse là où un ARN est attendu.
  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:eu-west-3:123456789012:log-group:/vpc/test/flow-logs"
    }
  }
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/test-vpc-flow-logs"
    }
  }
}

variables {
  name     = "test"
  cidr     = "10.10.0.0/16"
  az_count = 2
}

run "subnets_are_split_across_zones" {
  command = apply

  assert {
    condition     = length(aws_subnet.public) == 2 && length(aws_subnet.private) == 2
    error_message = "Il faut un sous-réseau public et un privé par zone."
  }
  assert {
    condition     = aws_subnet.public[0].availability_zone != aws_subnet.public[1].availability_zone
    error_message = "Les sous-réseaux doivent être dans des zones différentes."
  }
  assert {
    condition     = aws_subnet.private[0].cidr_block == "10.10.10.0/24"
    error_message = "Plan d'adressage inattendu pour les sous-réseaux privés."
  }
  assert {
    condition     = alltrue([for s in aws_subnet.public : s.map_public_ip_on_launch == false])
    error_message = "Aucune IP publique ne doit être attribuée automatiquement."
  }
}

run "no_nat_by_default_costs_nothing" {
  command = apply

  assert {
    condition     = length(aws_nat_gateway.this) == 0 && length(aws_route.private_nat) == 0
    error_message = "Par défaut, aucune NAT Gateway (coût fixe ~33 $/mois)."
  }
}

run "single_nat_is_shared_by_all_zones" {
  command = apply
  variables {
    nat_mode = "single"
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1 && length(aws_route.private_nat) == 2
    error_message = "Mode single : une NAT, une route par zone privée."
  }
}

run "per_az_nat_for_high_availability" {
  command = apply
  variables {
    nat_mode = "per_az"
    az_count = 3
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 3
    error_message = "Mode per_az : une NAT par zone."
  }
}

run "security_controls" {
  command = apply

  assert {
    condition     = aws_flow_log.this.traffic_type == "ALL"
    error_message = "Les journaux de flux doivent capturer tout le trafic."
  }
  assert {
    condition     = aws_vpc_endpoint.s3.vpc_endpoint_type == "Gateway"
    error_message = "L'endpoint S3 doit être de type Gateway (gratuit)."
  }
  assert {
    condition     = length(aws_default_security_group.this.ingress) == 0 && length(aws_default_security_group.this.egress) == 0
    error_message = "Le groupe de sécurité par défaut doit être vide."
  }
}

run "rejects_invalid_nat_mode" {
  command = plan
  variables {
    nat_mode = "always"
  }
  expect_failures = [var.nat_mode]
}

run "rejects_too_small_cidr" {
  command = plan
  variables {
    cidr = "10.10.0.0/24"
  }
  expect_failures = [var.cidr]
}

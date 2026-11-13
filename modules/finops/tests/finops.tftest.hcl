mock_provider "aws" {
  # ARN réaliste : le fournisseur AWS valide le format des ARN
  mock_resource "aws_ce_anomaly_monitor" {
    defaults = {
      arn = "arn:aws:ce::123456789012:anomalymonitor/11111111-2222-3333-4444-555555555555"
    }
  }
}

variables {
  name               = "acme"
  monthly_budget_usd = 10
  alert_emails       = ["finops@example.com"]
}

run "budget_alerts_on_actual_and_forecast" {
  command = apply

  assert {
    condition     = aws_budgets_budget.monthly.limit_amount == "10.00" && aws_budgets_budget.monthly.time_unit == "MONTHLY"
    error_message = "Budget mensuel de 10 USD attendu."
  }
  assert {
    condition     = length(aws_budgets_budget.monthly.notification) == 4
    error_message = "3 alertes sur la dépense réelle + 1 sur la prévision."
  }
  assert {
    condition     = contains([for n in aws_budgets_budget.monthly.notification : n.notification_type], "FORECASTED")
    error_message = "Une alerte sur la prévision de fin de mois est requise."
  }
}

run "anomaly_detection_enabled_by_default" {
  command = apply

  assert {
    condition     = length(aws_ce_anomaly_subscription.email) == 1
    error_message = "La détection d'anomalies doit être active par défaut."
  }
}

run "rejects_invalid_email" {
  command = plan
  variables {
    alert_emails = ["pas-un-email"]
  }
  expect_failures = [var.alert_emails]
}

run "rejects_zero_budget" {
  command = plan
  variables {
    monthly_budget_usd = 0
  }
  expect_failures = [var.monthly_budget_usd]
}

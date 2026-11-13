# =============================================================================
# FinOps : ne jamais découvrir une facture en fin de mois
#
#   - Budget mensuel avec alertes à 50 / 80 / 100 % de la dépense réelle, et
#     dès que la PRÉVISION de fin de mois dépasse le budget
#   - Détection d'anomalies : un pic inhabituel (NAT oubliée, boucle Lambda…)
#     déclenche un e-mail le jour même
#   - Étiquetage obligatoire (default_tags dans les environnements) pour
#     savoir qui dépense quoi
# =============================================================================

resource "aws_budgets_budget" "monthly" {
  name         = "${var.name}-monthly"
  budget_type  = "COST"
  limit_amount = format("%.2f", var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  dynamic "notification" {
    for_each = var.actual_thresholds_percent
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_email_addresses = var.alert_emails
    }
  }

  # Alerte anticipée : la tendance du mois va dépasser le budget
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.alert_emails
  }
}

resource "aws_ce_anomaly_monitor" "services" {
  count             = var.enable_anomaly_detection ? 1 : 0
  name              = "${var.name}-services"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "email" {
  count            = var.enable_anomaly_detection ? 1 : 0
  name             = "${var.name}-anomalies"
  frequency        = "DAILY"
  monitor_arn_list = [aws_ce_anomaly_monitor.services[0].arn]

  dynamic "subscriber" {
    for_each = var.alert_emails
    content {
      type    = "EMAIL"
      address = subscriber.value
    }
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = [tostring(var.anomaly_threshold_usd)]
    }
  }
}

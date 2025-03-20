################################
# Resource Health Alert
################################
data "azurerm_client_config" "current" {}

resource "azurerm_monitor_activity_log_alert" "this" {
  for_each            = var.resource_health_alert.resource_ids
  name                = "Resource_Health_${each.key}"
  resource_group_name = var.resource_group_name
  location            = "global"
  scopes              = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}"]

  criteria {
    category        = "ResourceHealth"
    resource_groups = [var.resource_group_name]
    resource_id     = each.value

    statuses = [
      "Active",
      "Resolved",
    ]

    resource_health {
      current = [
        "Degraded",
        "Unavailable",
      ]

      previous = [
        "Available",
      ]

      reason = [
        "PlatformInitiated",
        "UserInitiated",
        "Unknown",
      ]
    }
  }

  action {
    action_group_id = var.action_group[var.resource_health_alert.target_action_group].id
  }

  tags = var.tags
}

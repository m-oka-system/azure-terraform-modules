################################
# Service Health Alert
################################
data "azurerm_client_config" "current" {}

resource "azurerm_monitor_activity_log_alert" "this" {
  for_each            = var.service_health_alert
  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = "global"
  scopes              = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}"]

  criteria {
    category = "ServiceHealth"

    service_health {
      events = each.value.events
    }
  }

  action {
    action_group_id = var.action_group[each.value.target_action_group].id
  }

  tags = var.tags
}

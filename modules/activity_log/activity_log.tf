################################
# Activity Log
################################
data "azurerm_client_config" "current" {}

resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = "activity-log-diag-setting"
  target_resource_id         = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = var.activity_log_categories

    content {
      category = enabled_log.value
    }
  }
}

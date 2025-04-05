################################
# Activity Log Alert
################################
resource "azurerm_monitor_activity_log_alert" "this" {
  for_each            = var.activity_log_alert
  name                = "${each.value.signal_name}_${var.resource_group_name}"
  resource_group_name = var.resource_group_name
  location            = "global"
  scopes              = each.value.scopes
  enabled             = each.value.enabled

  criteria {
    category       = each.value.criteria.category
    operation_name = each.key
    statuses       = each.value.criteria.statuses
    resource_type  = each.value.criteria.resource_type
  }

  action {
    action_group_id = var.action_group[each.value.target_action_group].id
  }

  tags = var.tags
}

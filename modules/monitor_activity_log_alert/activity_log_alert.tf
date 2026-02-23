################################
# Activity Log Alert
################################
locals {
  activity_alerts = flatten([
    for resource_type, config in var.activity_log_alert : [
      for resource_key, resource in config.resources : [
        for operation_name, operation in config.operations : {
          key            = "${resource_type}_${operation_name}_${resource_key}"
          resource_type  = resource_type
          resource_name  = resource.name
          scope_id       = resource.id
          operation_name = "${resource_type}/${operation_name}"
          operation      = operation
        }
      ]
    ]
  ])
}

resource "azurerm_monitor_activity_log_alert" "this" {
  for_each            = { for alert in local.activity_alerts : alert.key => alert }
  name                = "${each.value.resource_name}_${each.value.operation.display_name}"
  resource_group_name = var.resource_group_name
  location            = "global"
  scopes              = [each.value.scope_id]
  enabled             = each.value.operation.enabled

  criteria {
    category       = each.value.operation.category
    operation_name = each.value.operation_name
    statuses       = each.value.operation.statuses
    resource_type  = each.value.resource_type
    resource_id    = each.value.scope_id
  }

  action {
    action_group_id = var.action_group[each.value.operation.target_action_group].id
  }

  tags = var.tags
}

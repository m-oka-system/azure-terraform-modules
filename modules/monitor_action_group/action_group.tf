################################
# Action group
################################
resource "azurerm_monitor_action_group" "this" {
  for_each            = var.action_group
  name                = "ag-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name = var.resource_group_name
  short_name          = replace("ag-${substr(each.value.name, 0, 4)}-${substr(var.common.project, 0, 5)}-${substr(var.common.env, 0, 1)}", "-", "") # 12文字以内

  dynamic "email_receiver" {
    for_each = each.value.email_receivers
    content {
      name                    = email_receiver.value.name
      email_address           = email_receiver.value.email_address
      use_common_alert_schema = email_receiver.value.use_common_alert_schema
    }
  }

  tags = var.tags
}

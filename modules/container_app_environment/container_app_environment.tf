################################
# Container App Environment
################################
resource "azurerm_container_app_environment" "this" {
  for_each                   = var.container_app_environment
  name                       = "cae-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name        = var.resource_group_name
  location                   = var.common.location
  zone_redundancy_enabled    = each.value.zone_redundancy_enabled
  infrastructure_subnet_id   = var.subnet[each.value.target_subnet].id
  logs_destination           = each.value.logs_destination
  log_analytics_workspace_id = each.value.logs_destination == "log-analytics" ? var.log_analytics_workspace[each.value.target_log_analytics_workspace].id : null

  tags = var.tags
}

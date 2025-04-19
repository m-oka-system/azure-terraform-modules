################################
# Container App Environment
################################
resource "azurerm_container_app_environment" "this" {
  for_each                           = var.container_app_environment
  name                               = "cae-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name                = var.resource_group_name
  infrastructure_resource_group_name = "${var.resource_group_name}-cae"
  location                           = var.common.location
  zone_redundancy_enabled            = each.value.zone_redundancy_enabled
  infrastructure_subnet_id           = var.subnet[each.value.target_subnet].id
  logs_destination                   = each.value.logs_destination
  log_analytics_workspace_id         = each.value.logs_destination == "log-analytics" ? var.log_analytics_workspace[each.value.target_log_analytics_workspace].id : null

  workload_profile {
    name                  = each.value.workload_profile.name
    workload_profile_type = each.value.workload_profile.workload_profile_type
    minimum_count         = each.value.workload_profile.minimum_count
    maximum_count         = each.value.workload_profile.maximum_count
  }

  tags = var.tags
}

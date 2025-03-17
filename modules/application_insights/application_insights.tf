################################
# Application Insights
################################
resource "azurerm_application_insights" "this" {
  for_each                   = var.application_insights
  name                       = "appi-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name        = var.resource_group_name
  location                   = var.common.location
  workspace_id               = var.log_analytics[each.value.target_workspace].id
  application_type           = each.value.application_type
  retention_in_days          = each.value.retention_in_days
  internet_ingestion_enabled = each.value.internet_ingestion_enabled
  internet_query_enabled     = each.value.internet_query_enabled

  tags = var.tags
}

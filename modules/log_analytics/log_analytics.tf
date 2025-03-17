################################
# Log Analytics workspace
################################
resource "azurerm_log_analytics_workspace" "this" {
  for_each                   = var.log_analytics
  name                       = "log-${var.common.project}-${var.common.env}"
  resource_group_name        = var.resource_group_name
  location                   = var.common.location
  sku                        = each.value.sku
  retention_in_days          = each.value.retention_in_days
  internet_ingestion_enabled = each.value.internet_ingestion_enabled
  internet_query_enabled     = each.value.internet_query_enabled

  tags = var.tags
}

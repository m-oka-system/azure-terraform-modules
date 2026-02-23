###################################
# Azure Monitor Private Link Scope
###################################
resource "azurerm_monitor_private_link_scope" "this" {
  for_each              = var.private_link_scope
  name                  = "ampls-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name   = var.resource_group_name
  ingestion_access_mode = each.value.ingestion_access_mode
  query_access_mode     = each.value.query_access_mode

  tags = var.tags
}

resource "azurerm_monitor_private_link_scoped_service" "this" {
  for_each            = var.private_link_scoped_service
  name                = each.value.name
  resource_group_name = var.resource_group_name
  scope_name          = azurerm_monitor_private_link_scope.this[each.value.target_ampls].name
  linked_resource_id  = each.value.linked_resource_id
}

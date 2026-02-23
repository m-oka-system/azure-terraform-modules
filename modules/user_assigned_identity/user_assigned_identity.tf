################################
# User Assigned Managed ID
################################
data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "this" {
  for_each            = var.user_assigned_identity
  name                = "id-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name = var.resource_group_name
  location            = var.common.location

  tags = var.tags
}

resource "azurerm_role_assignment" "this" {
  for_each             = var.role_assignment
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.this[each.value.target_identity].principal_id
}

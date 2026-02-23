################################
# User Assigned Managed ID
################################
resource "azurerm_user_assigned_identity" "this" {
  for_each            = var.user_assigned_identity
  name                = "id-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name = var.resource_group_name
  location            = var.common.location

  tags = var.tags
}

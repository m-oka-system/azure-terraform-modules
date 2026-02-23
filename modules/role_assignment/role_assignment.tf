################################
# Role Assignment
################################
resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignment

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}

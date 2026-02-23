################################
# Role Definition
################################

resource "azurerm_role_definition" "this" {
  for_each = var.role_definition

  name        = each.value.name
  scope       = var.scope
  description = each.value.description

  permissions {
    actions          = each.value.actions
    not_actions      = each.value.not_actions
    data_actions     = each.value.data_actions
    not_data_actions = each.value.not_data_actions
  }

  assignable_scopes = var.assignable_scopes
}

################################
# Automation Account
################################
resource "azurerm_automation_account" "this" {
  name                = "aa-${var.common.project}-${var.common.env}"
  location            = var.common.location
  resource_group_name = var.resource_group_name
  sku_name            = "Basic"

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "automation_contributor" {
  scope                = var.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_automation_account.this.identity[0].principal_id
}

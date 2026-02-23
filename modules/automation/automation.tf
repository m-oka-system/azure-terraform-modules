################################
# Automation Account
################################
resource "azurerm_automation_account" "this" {
  name                          = "aa-${var.common.project}-${var.common.env}"
  location                      = var.common.location
  resource_group_name           = var.resource_group_name
  sku_name                      = "Basic"
  local_authentication_enabled  = false
  public_network_access_enabled = false

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

# Automation 変数
resource "azurerm_automation_variable_string" "resource_group_name" {
  name                    = "ResourceGroupName"
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  value                   = var.resource_group_name
  encrypted               = false
}

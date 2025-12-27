################################
# Federated Identity Credential
################################
resource "azurerm_federated_identity_credential" "this" {
  name                = "gha-${var.common.project}-${var.common.env}"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  parent_id           = var.parent_id
  subject             = var.subject
}

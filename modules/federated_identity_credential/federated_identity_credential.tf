################################
# Federated Identity Credential
################################
resource "azurerm_federated_identity_credential" "this" {
  for_each = var.federated_identity_credential

  name      = each.value.name
  audience  = ["api://AzureADTokenExchange"]
  issuer    = each.value.issuer
  parent_id = each.value.parent_id
  subject   = each.value.subject
}

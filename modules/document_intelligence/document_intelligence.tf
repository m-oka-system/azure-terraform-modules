################################
# Azure Document Intelligence
################################
data "azurerm_client_config" "current" {}

resource "azurerm_cognitive_account" "this" {
  for_each              = var.document_intelligence
  name                  = "doc-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name   = var.resource_group_name
  location              = each.value.location
  kind                  = each.value.kind
  sku_name              = each.value.sku_name
  custom_subdomain_name = "doc-${each.value.name}-${var.common.project}-${var.common.env}"

  identity {
    type = "SystemAssigned"
  }

  network_acls {
    default_action = each.value.network_acls.default_action
    ip_rules       = join(",", lookup(each.value.network_acls, "ip_rules", null)) == "MyIP" ? var.allowed_cidr : lookup(each.value.network_acls, "ip_rules", null)
  }


  tags = var.tags
}

resource "azurerm_role_assignment" "this" {
  for_each             = var.document_intelligence
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_cognitive_account.this[each.key].identity[0].principal_id
}

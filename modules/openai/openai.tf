################################
# Azure OpenAI Service
################################
resource "azurerm_cognitive_account" "this" {
  for_each              = var.openai
  name                  = "oai-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name   = var.resource_group_name
  location              = each.value.location
  kind                  = each.value.kind
  sku_name              = each.value.sku_name
  custom_subdomain_name = "oai-${each.value.name}-${var.common.project}-${var.common.env}"

  network_acls {
    default_action = each.value.network_acls.default_action
    ip_rules       = join(",", lookup(each.value.network_acls, "ip_rules", null)) == "MyIP" ? var.allowed_cidr : lookup(each.value.network_acls, "ip_rules", null)
  }

  tags = var.tags
}

resource "azurerm_cognitive_deployment" "this" {
  for_each               = var.openai_deployment
  name                   = each.value.name
  cognitive_account_id   = azurerm_cognitive_account.this[each.value.target_openai].id
  version_upgrade_option = each.value.version_upgrade_option

  model {
    format  = "OpenAI"
    name    = each.value.model.name
    version = each.value.model.version
  }

  sku {
    name     = each.value.sku.name
    capacity = each.value.sku.capacity
  }
}

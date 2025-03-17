################################
# Key Vault
################################
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  for_each                   = var.key_vault
  name                       = "vault-${each.value.name}-${var.common.project}-${var.common.env}"
  location                   = var.common.location
  resource_group_name        = var.resource_group_name
  sku_name                   = each.value.sku_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization  = each.value.enable_rbac_authorization
  purge_protection_enabled   = each.value.purge_protection_enabled
  soft_delete_retention_days = each.value.soft_delete_retention_days
  access_policy              = []

  network_acls {
    default_action             = each.value.network_acls.default_action
    bypass                     = each.value.network_acls.bypass
    ip_rules                   = join(",", lookup(each.value.network_acls, "ip_rules", null)) == "MyIP" ? var.allowed_cidr : lookup(each.value.network_acls, "ip_rules", null)
    virtual_network_subnet_ids = each.value.network_acls.virtual_network_subnet_ids
  }

  tags = var.tags
}

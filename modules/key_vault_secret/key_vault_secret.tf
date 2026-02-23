################################
# Key Vault secrets
################################
resource "azurerm_key_vault_secret" "this" {
  for_each     = var.key_vault_secret.secrets
  name         = upper(replace(each.key, "_", "-"))
  value        = each.value
  key_vault_id = var.key_vault[var.key_vault_secret.target_key_vault].id
}

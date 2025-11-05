################################
# Data Protection Backup Vault
################################
resource "azurerm_data_protection_backup_vault" "this" {
  for_each            = var.backup_vault
  name                = "bv-${each.value.name}-${var.common.project}-${var.common.env}-${var.random}"
  resource_group_name = var.resource_group_name
  location            = var.common.location
  datastore_type      = each.value.datastore_type
  redundancy          = each.value.redundancy

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

################################
# Backup Policy for Blob Storage
################################
resource "azurerm_data_protection_backup_policy_blob_storage" "this" {
  for_each           = var.backup_policy_blob
  name               = "bp-blob-${each.value.name}-${var.common.project}-${var.common.env}"
  vault_id           = azurerm_data_protection_backup_vault.this[each.value.target_backup_vault].id
  retention_duration = each.value.retention_duration
}

################################
# Role Assignment for Backup
################################
resource "azurerm_role_assignment" "backup_contributor" {
  for_each             = var.backup_instance_blob
  scope                = each.value.storage_account_id
  role_definition_name = "Storage Account Backup Contributor"
  principal_id         = azurerm_data_protection_backup_vault.this[each.value.target_backup_vault].identity[0].principal_id
}

################################
# Backup Instance for Blob Storage
################################
resource "azurerm_data_protection_backup_instance_blob_storage" "this" {
  for_each           = var.backup_instance_blob
  name               = "bi-blob-${each.value.name}-${var.common.project}-${var.common.env}"
  vault_id           = azurerm_data_protection_backup_vault.this[each.value.target_backup_vault].id
  location           = var.common.location
  storage_account_id = each.value.storage_account_id
  backup_policy_id   = azurerm_data_protection_backup_policy_blob_storage.this[each.value.target_backup_policy].id

  depends_on = [
    azurerm_role_assignment.backup_contributor
  ]
}

output "backup_vault" {
  value = azurerm_data_protection_backup_vault.this
}

output "backup_policy_blob" {
  value = azurerm_data_protection_backup_policy_blob_storage.this
}

output "backup_instance_blob" {
  value = azurerm_data_protection_backup_instance_blob_storage.this
}

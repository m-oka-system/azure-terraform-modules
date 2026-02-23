output "storage_account" {
  value = azurerm_storage_account.this
}

output "storage_container" {
  value = azurerm_storage_container.this
}

output "storage_static_website" {
  value = azurerm_storage_account_static_website.this
}

output "storage_management_policy" {
  value = azurerm_storage_management_policy.this
}

output "storage_defender" {
  value = azurerm_security_center_storage_defender.this
}

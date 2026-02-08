output "vnet" {
  description = "仮想ネットワークのリソース情報"
  value       = azurerm_virtual_network.this
}

output "subnet" {
  description = "サブネットのリソース情報"
  value       = azurerm_subnet.this
}

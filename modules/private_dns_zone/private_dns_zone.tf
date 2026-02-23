################################
# Private DNS zone
################################
resource "azurerm_private_dns_zone" "this" {
  for_each            = var.private_dns_zone
  name                = each.value
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each              = var.private_dns_zone
  name                  = "vnetlink"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  virtual_network_id    = var.vnet[var.target_vnet].id

  tags = var.tags
}

################################
# Azure DNS
################################
resource "azurerm_dns_zone" "this" {
  for_each            = var.dns_zone
  name                = each.value.dns_zone_name
  resource_group_name = var.resource_group_name

  tags = var.tags
}

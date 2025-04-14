################################
# Private Endpoint
################################
resource "azurerm_private_endpoint" "this" {
  for_each                      = var.private_endpoint
  name                          = "pe-${each.value.name}"
  resource_group_name           = var.resource_group_name
  location                      = var.common.location
  subnet_id                     = each.value.subnet_id
  custom_network_interface_name = "pe-nic-${each.value.name}"

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = each.value.private_dns_zone_ids
  }

  private_service_connection {
    name                           = "connection"
    is_manual_connection           = false
    private_connection_resource_id = each.value.private_connection_resource_id
    subresource_names              = each.value.subresource_names
  }

  tags = var.tags
}

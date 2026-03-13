################################
# Private DNS Resolver
################################
resource "azurerm_private_dns_resolver" "this" {
  name                = "dnspr-${var.common.project}-${var.common.env}"
  resource_group_name = var.resource_group_name
  location            = var.common.location
  virtual_network_id  = var.virtual_network_id

  tags = var.tags
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "this" {
  name                    = "inbound-endpoint"
  private_dns_resolver_id = azurerm_private_dns_resolver.this.id
  location                = var.common.location

  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = var.subnet_id
  }

  tags = var.tags
}

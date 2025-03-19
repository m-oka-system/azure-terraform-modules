################################
# NAT Gateway
################################
resource "azurerm_public_ip" "this" {
  name                = "ip-nat-${var.common.project}-${var.common.env}"
  resource_group_name = var.resource_group_name
  location            = var.common.location
  sku                 = var.nat_gateway.public_ip.sku
  allocation_method   = var.nat_gateway.public_ip.allocation_method
  zones               = var.nat_gateway.public_ip.zones

  tags = var.tags
}

resource "azurerm_nat_gateway" "this" {
  name                    = "nat-${var.common.project}-${var.common.env}"
  resource_group_name     = var.resource_group_name
  location                = var.common.location
  sku_name                = var.nat_gateway.sku_name
  idle_timeout_in_minutes = var.nat_gateway.idle_timeout_in_minutes
  zones                   = var.nat_gateway.zones

  tags = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.this.id
}

resource "azurerm_subnet_nat_gateway_association" "this" {
  for_each       = toset(var.nat_gateway.target_subnets)
  subnet_id      = var.subnet[each.value].id
  nat_gateway_id = azurerm_nat_gateway.this.id
}

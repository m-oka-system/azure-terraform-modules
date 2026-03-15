################################
# VPN Gateway
################################
resource "azurerm_public_ip" "this" {
  name                = "ip-vgw-${var.common.project}-${var.common.env}"
  resource_group_name = var.resource_group_name
  location            = var.common.location
  sku                 = var.vpn_gateway.public_ip.sku
  allocation_method   = var.vpn_gateway.public_ip.allocation_method
  zones               = var.vpn_gateway.public_ip.zones

  tags = var.tags
}

resource "azurerm_virtual_network_gateway" "this" {
  name                = "vgw-${var.common.project}-${var.common.env}"
  location            = var.common.location
  resource_group_name = var.resource_group_name
  type                = var.vpn_gateway.type
  vpn_type            = var.vpn_gateway.vpn_type
  sku                 = var.vpn_gateway.sku
  active_active       = var.vpn_gateway.active_active
  bgp_enabled         = var.vpn_gateway.bgp_enabled
  generation          = var.vpn_gateway.generation

  ip_configuration {
    name                          = "vnetGatewayConfig"
    subnet_id                     = var.subnet[var.vpn_gateway.target_subnet].id
    public_ip_address_id          = azurerm_public_ip.this.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_local_network_gateway" "this" {
  for_each = var.local_network_gateway

  name                = "lgw-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name = var.resource_group_name
  location            = var.common.location
  gateway_address     = each.value.gateway_address
  address_space       = each.value.address_space

  tags = var.tags
}

resource "azurerm_virtual_network_gateway_connection" "this" {
  for_each = var.local_network_gateway

  name                       = "vcn-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name        = var.resource_group_name
  location                   = var.common.location
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.this.id
  local_network_gateway_id   = azurerm_local_network_gateway.this[each.key].id
  shared_key                 = each.value.shared_key

  tags = var.tags
}

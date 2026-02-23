resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "${var.hub_vnet_name}-to-${var.spoke_vnet_name}"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = var.hub_vnet_name
  remote_virtual_network_id    = var.spoke_vnet_id
  allow_virtual_network_access = true  # Hub と Spoke 間の直接通信を許可するか（基本的なピアリング通信、通常は true）
  allow_forwarded_traffic      = true  # Spoke から Hub に送られる転送トラフィック（他の Spoke や オンプレミス宛てのトラフィック）を Hub が受け取ることを許可するか（Spoke 間通信が必要な場合は true）
  allow_gateway_transit        = false # Hub が自身の VPN/ExpressRoute Gateway を Spoke に使わせるか（Hub にゲートウェイがある場合のみ有効）
  use_remote_gateways          = false # Hub が Spoke の VPN/ExpressRoute Gateway を使用するか（通常 Hub では false）
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "${var.spoke_vnet_name}-to-${var.hub_vnet_name}"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = var.spoke_vnet_name
  remote_virtual_network_id    = var.hub_vnet_id
  allow_virtual_network_access = true  # Spoke と Hub 間の直接通信を許可するか（基本的なピアリング通信、通常は true）
  allow_forwarded_traffic      = true  # Hub から Spoke に送られる転送トラフィック（他の Spoke や オンプレミスからのトラフィック）を Spoke が受け取ることを許可するか（Spoke 間通信が必要な場合は true）
  allow_gateway_transit        = false # Spoke が自身の VPN/ExpressRoute Gateway を Hub に使わせるか（通常 Spoke では false）
  use_remote_gateways          = false # Spoke が Hub の VPN/ExpressRoute Gateway を使用するか（Hub にゲートウェイがある場合は true）
}

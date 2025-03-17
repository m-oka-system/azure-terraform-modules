################################
# Network security group
################################
resource "azurerm_network_security_group" "this" {
  for_each            = var.network_security_group
  name                = "nsg-${each.value.name}-${var.common.project}-${var.common.env}"
  location            = var.common.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_network_security_rule" "this" {
  # 配列をマップに変換
  for_each = { for rule in var.network_security_rule : format("%s-%s", rule.target_nsg, rule.name) => rule }

  resource_group_name          = var.resource_group_name
  network_security_group_name  = azurerm_network_security_group.this[each.value.target_nsg].name
  name                         = each.value.name
  priority                     = each.value.priority
  direction                    = each.value.direction
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_port_range            = lookup(each.value, "source_port_range", null)
  source_port_ranges           = lookup(each.value, "source_port_ranges", null)
  destination_port_range       = lookup(each.value, "destination_port_range", null)
  destination_port_ranges      = lookup(each.value, "destination_port_ranges", null)
  source_address_prefix        = lookup(each.value, "source_address_prefix", null)
  source_address_prefixes      = lookup(each.value, "source_address_prefixes", null)
  destination_address_prefix   = lookup(each.value, "destination_address_prefix", null)
  destination_address_prefixes = lookup(each.value, "destination_address_prefixes", null)
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each                  = var.network_security_group
  subnet_id                 = var.subnet[each.value.target_subnet].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}

################################
# Bastion
################################
resource "azurerm_public_ip" "this" {
  name                = "ip-bastion-${var.common.project}-${var.common.env}"
  resource_group_name = var.resource_group_name
  location            = var.common.location
  sku                 = var.bastion.public_ip.sku
  allocation_method   = var.bastion.public_ip.allocation_method
  zones               = var.bastion.public_ip.zones

  tags = var.tags
}

resource "azurerm_bastion_host" "this" {
  name                = "bastion-${var.common.project}-${var.common.env}"
  resource_group_name = var.resource_group_name
  location            = var.common.location
  sku                 = var.bastion.sku
  scale_units         = var.bastion.scale_units
  zones               = var.bastion.zones

  copy_paste_enabled        = var.bastion.copy_paste_enabled
  file_copy_enabled         = var.bastion.file_copy_enabled
  ip_connect_enabled        = var.bastion.ip_connect_enabled
  kerberos_enabled          = var.bastion.kerberos_enabled
  shareable_link_enabled    = var.bastion.shareable_link_enabled
  tunneling_enabled         = var.bastion.tunneling_enabled
  session_recording_enabled = var.bastion.session_recording_enabled

  ip_configuration {
    name                 = "IpConf"
    subnet_id            = var.subnet[var.bastion.target_subnet].id
    public_ip_address_id = azurerm_public_ip.this.id
  }
}

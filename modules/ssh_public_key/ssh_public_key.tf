################################
# SSH Public Key
################################
resource "tls_private_key" "rsa-4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_ssh_public_key" "this" {
  name                = "ssh-key-${var.common.project}-${var.common.env}"
  resource_group_name = var.resource_group_name
  location            = var.common.location
  public_key          = tls_private_key.rsa-4096.public_key_openssh

  tags = var.tags
}

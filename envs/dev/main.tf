resource "random_integer" "num" {
  min = 10000
  max = 99999
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.common.project}-${var.common.env}"
  location = var.common.location

  tags = local.common.tags
}

module "vnet" {
  source              = "../../modules/vnet"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  vnet                = var.vnet
  subnet              = var.subnet
}

module "network_security_group" {
  source                 = "../../modules/network_security_group"
  common                 = var.common
  resource_group_name    = azurerm_resource_group.rg.name
  tags                   = azurerm_resource_group.rg.tags
  network_security_group = var.network_security_group
  network_security_rule  = var.network_security_rule
  subnet                 = module.vnet.subnet
}

module "storage" {
  source                    = "../../modules/storage"
  common                    = var.common
  resource_group_name       = azurerm_resource_group.rg.name
  tags                      = azurerm_resource_group.rg.tags
  random                    = local.common.random
  storage                   = var.storage
  blob_container            = var.blob_container
  allowed_cidr              = var.allowed_cidr
  storage_management_policy = var.storage_management_policy
}

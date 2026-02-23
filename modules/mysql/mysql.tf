##########################################
# Azure Database for MySQL Flexible Server
##########################################
resource "azurerm_mysql_flexible_server" "this" {
  for_each                          = var.mysql_flexible_server
  name                              = "mysql-${each.value.name}-${var.common.project}-${var.common.env}-${var.random}"
  resource_group_name               = var.resource_group_name
  location                          = var.common.location
  administrator_login               = var.mysql_authentication[each.key].administrator_login
  administrator_password_wo         = var.mysql_authentication[each.key].administrator_password_wo
  administrator_password_wo_version = var.mysql_authentication[each.key].administrator_password_wo_version
  sku_name                          = each.value.sku_name
  version                           = each.value.version
  backup_retention_days             = each.value.backup_retention_days
  geo_redundant_backup_enabled      = each.value.geo_redundant_backup_enabled
  delegated_subnet_id               = var.subnet[each.value.target_subnet].id
  private_dns_zone_id               = azurerm_private_dns_zone.this[each.key].id
  zone                              = each.value.zone

  # Zone Redundancy (Requires General Purpose or higher SKU)
  dynamic "high_availability" {
    for_each = each.value.high_availability != null ? [true] : []

    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = each.value.high_availability.standby_availability_zone
    }
  }

  storage {
    auto_grow_enabled = each.value.storage.auto_grow_enabled
    iops              = each.value.storage.iops
    size_gb           = each.value.storage.size_gb
  }

  tags = var.tags

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.this
  ]
}

resource "azurerm_mysql_flexible_database" "this" {
  for_each            = var.mysql_flexible_database
  name                = each.value.name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.this[each.value.target_mysql_server].name
  charset             = each.value.charset
  collation           = each.value.collation
}

resource "azurerm_mysql_flexible_server_configuration" "ssl_config" {
  for_each            = var.mysql_flexible_server
  name                = "require_secure_transport"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.this[each.key].name
  value               = "ON"
}

resource "azurerm_private_dns_zone" "this" {
  for_each            = var.mysql_flexible_server
  name                = "mysql-${each.value.name}-${var.common.project}-${var.common.env}-${var.random}.private.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each              = var.mysql_flexible_server
  name                  = "mysqlfsVnetZone"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  virtual_network_id    = var.vnet[each.value.target_vnet].id
}

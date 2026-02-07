################################################
# Azure Database for PostgreSQL Flexible Server
################################################
resource "azurerm_postgresql_flexible_server" "this" {
  for_each                          = var.postgresql_flexible_server
  name                              = "psql-${each.value.name}-${var.common.project}-${var.common.env}-${var.random}"
  resource_group_name               = var.resource_group_name
  location                          = var.common.location
  administrator_login               = var.postgresql_authentication[each.key].administrator_login
  administrator_password_wo         = var.postgresql_authentication[each.key].administrator_password_wo
  administrator_password_wo_version = var.postgresql_authentication[each.key].administrator_password_wo_version
  sku_name                          = each.value.sku_name
  version                           = each.value.version
  backup_retention_days             = each.value.backup_retention_days
  geo_redundant_backup_enabled      = each.value.geo_redundant_backup_enabled
  delegated_subnet_id               = var.subnet[each.value.target_subnet].id
  private_dns_zone_id               = azurerm_private_dns_zone.this[each.key].id
  public_network_access_enabled     = each.value.public_network_access_enabled
  zone                              = each.value.zone

  storage_mb   = each.value.storage_mb
  storage_tier = each.value.storage_tier

  dynamic "high_availability" {
    for_each = each.value.high_availability != null ? [true] : []

    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = each.value.high_availability.standby_availability_zone
    }
  }

  tags = var.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.this]
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  for_each  = var.postgresql_flexible_database
  name      = each.value.name
  server_id = azurerm_postgresql_flexible_server.this[each.value.target_postgresql_server].id
  charset   = each.value.charset
  collation = each.value.collation
}

resource "azurerm_postgresql_flexible_server_configuration" "ssl" {
  for_each  = var.postgresql_flexible_server
  name      = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.this[each.key].id
  value     = "ON"
}

resource "azurerm_private_dns_zone" "this" {
  for_each            = var.postgresql_flexible_server
  name                = "psql-${each.value.name}-${var.common.project}-${var.common.env}-${var.random}.private.postgres.database.azure.com"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each              = var.postgresql_flexible_server
  name                  = "psqlfsVnetZone"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  virtual_network_id    = var.vnet[each.value.target_vnet].id

  tags = var.tags
}

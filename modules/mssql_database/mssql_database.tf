##########################################
# Azure SQL Database
##########################################
resource "azurerm_mssql_database" "this" {
  for_each                            = var.mssql_database
  name                                = "sqldb-${each.key}-${var.common.project}-${var.common.env}"
  server_id                           = var.server_id
  collation                           = each.value.collation
  license_type                        = "LicenseIncluded"
  max_size_gb                         = each.value.max_size_gb
  sku_name                            = each.value.sku_name
  zone_redundant                      = each.value.zone_redundant
  storage_account_type                = each.value.storage_account_type
  transparent_data_encryption_enabled = true

  # Backup settings
  short_term_retention_policy {
    retention_days           = each.value.short_term_retention_policy.retention_days
    backup_interval_in_hours = each.value.short_term_retention_policy.backup_interval_in_hours
  }

  tags = var.tags
}

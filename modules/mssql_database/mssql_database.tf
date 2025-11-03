##########################################
# Azure SQL Database
##########################################
resource "azurerm_mssql_database" "this" {
  name                                = "sqldb-${var.common.project}-${var.common.env}"
  server_id                           = var.server_id
  collation                           = "Japanese_CI_AS"
  license_type                        = "LicenseIncluded"
  max_size_gb                         = 2
  sku_name                            = "Basic"
  zone_redundant                      = var.common.env == "prod" ? true : false
  storage_account_type                = "Local"
  transparent_data_encryption_enabled = true

  # Backup settings
  short_term_retention_policy {
    retention_days           = 35 # 1 - 35 days (Basic は最大 7 日)
    backup_interval_in_hours = 12 # 12 or 24 hours
  }

  tags = var.tags
}

# Microsoft Defender for SQL
resource "azurerm_security_center_subscription_pricing" "this" {
  tier          = "Standard"
  resource_type = "SqlServers"
}

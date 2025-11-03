##########################################
# Azure SQL Server
##########################################
resource "random_password" "admin_password" {
  length           = 16
  override_special = "!#$%&*()-_=+[]{}<>:?"
  special          = true
}

# Azure SQL Server
resource "azurerm_mssql_server" "this" {
  name                                 = "mssql-${var.common.project}-${var.common.env}-${var.random}"
  resource_group_name                  = var.resource_group_name
  location                             = var.common.location
  version                              = "12.0"
  administrator_login                  = "sqladmin"
  administrator_login_password         = random_password.admin_password.result
  minimum_tls_version                  = "1.2"
  public_network_access_enabled        = true
  outbound_network_restriction_enabled = false
  primary_user_assigned_identity_id    = var.identity_id

  identity {
    type = "UserAssigned"
    identity_ids = [
      var.identity_id
    ]
  }

  # 高速構成を使用して脆弱性評価を有効化 (Microsoft Defender for SQL が必要)
  express_vulnerability_assessment_enabled = true

  tags = var.tags
}

# Firewall Rules
resource "azurerm_mssql_firewall_rule" "this" {
  for_each = var.firewall_rules

  name             = each.key
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

# Audit Policy (監査ログ)
resource "azurerm_mssql_server_extended_auditing_policy" "this" {
  server_id              = azurerm_mssql_server.this.id
  storage_endpoint       = var.storage_endpoint
  log_monitoring_enabled = true
  retention_in_days      = 7
}

# Advanced Threat Protection (脅威保護)
resource "azurerm_mssql_server_security_alert_policy" "this" {
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mssql_server.this.name
  state               = "Enabled"
}

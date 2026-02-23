##########################################
# Azure SQL Server
##########################################
data "azurerm_client_config" "current" {}

resource "random_password" "admin_password" {
  count            = var.azuread_authentication_only ? 0 : 1
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
  administrator_login                  = var.azuread_authentication_only ? null : "sqladmin"
  administrator_login_password         = var.azuread_authentication_only ? null : random_password.admin_password[0].result
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
  express_vulnerability_assessment_enabled = var.defender_for_cloud_enabled

  azuread_administrator {
    login_username              = data.azurerm_client_config.current.object_id
    object_id                   = data.azurerm_client_config.current.object_id
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    azuread_authentication_only = var.azuread_authentication_only
  }

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
  server_id                       = azurerm_mssql_server.this.id
  storage_endpoint                = var.storage_endpoint
  storage_account_subscription_id = data.azurerm_client_config.current.subscription_id
  log_monitoring_enabled          = true
  retention_in_days               = 7
}

# Advanced Threat Protection (脅威保護)
resource "azurerm_mssql_server_security_alert_policy" "this" {
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mssql_server.this.name
  state               = var.defender_for_cloud_enabled ? "Enabled" : "Disabled"
}

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
  allowed_cidr              = split(",", var.allowed_cidr)
  storage_management_policy = var.storage_management_policy
}

module "key_vault" {
  source              = "../../modules/key_vault"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  key_vault           = var.key_vault
  allowed_cidr        = split(",", var.allowed_cidr)
}

module "log_analytics" {
  source              = "../../modules/log_analytics"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  log_analytics       = var.log_analytics
}

module "application_insights" {
  source               = "../../modules/application_insights"
  common               = var.common
  resource_group_name  = azurerm_resource_group.rg.name
  tags                 = azurerm_resource_group.rg.tags
  application_insights = var.application_insights
  log_analytics        = module.log_analytics.log_analytics
}

module "user_assigned_identity" {
  source                 = "../../modules/user_assigned_identity"
  common                 = var.common
  resource_group_name    = azurerm_resource_group.rg.name
  tags                   = azurerm_resource_group.rg.tags
  user_assigned_identity = var.user_assigned_identity
  role_assignment        = var.role_assignment
}

module "activity_log" {
  source                     = "../../modules/activity_log"
  log_analytics_workspace_id = module.log_analytics.log_analytics["logs"].id
  activity_log_categories    = toset(local.activity_log_categories)
}

module "openai" {
  source              = "../../modules/openai"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  openai              = var.openai
  openai_deployment   = var.openai_deployment
  allowed_cidr        = split(",", var.allowed_cidr)
}

module "aisearch" {
  count = local.aisearch_enabled ? 1 : 0

  source              = "../../modules/aisearch"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  aisearch            = var.aisearch
  allowed_cidr = concat(
    split(",", var.allowed_cidr),
    split(",", local.azure_portal_ips.aisearch)
  )
}

module "cosmosdb" {
  count = local.cosmosdb_enabled ? 1 : 0

  source                 = "../../modules/cosmosdb"
  common                 = var.common
  resource_group_name    = azurerm_resource_group.rg.name
  tags                   = azurerm_resource_group.rg.tags
  cosmosdb_account       = var.cosmosdb_account
  cosmosdb_sql_database  = var.cosmosdb_sql_database
  cosmosdb_sql_container = var.cosmosdb_sql_container
  allowed_cidr = concat(
    split(",", var.allowed_cidr),
    split(",", local.azure_portal_ips.cosmosdb)
  )
}

module "mysql" {
  count = local.mysql_enabled ? 1 : 0

  source                  = "../../modules/mysql"
  common                  = var.common
  resource_group_name     = azurerm_resource_group.rg.name
  tags                    = azurerm_resource_group.rg.tags
  random                  = local.common.random
  mysql_flexible_server   = var.mysql_flexible_server
  mysql_authentication    = var.mysql_authentication
  mysql_flexible_database = var.mysql_flexible_database
  vnet                    = module.vnet.vnet
  subnet                  = module.vnet.subnet
}

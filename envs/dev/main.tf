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

module "vnet_peering_hub_spoke1" {
  source              = "../../modules/vnet_peering"
  resource_group_name = azurerm_resource_group.rg.name
  hub_vnet_name       = module.vnet.vnet["hub"].name
  hub_vnet_id         = module.vnet.vnet["hub"].id
  spoke_vnet_name     = module.vnet.vnet["spoke1"].name
  spoke_vnet_id       = module.vnet.vnet["spoke1"].id
}

module "vnet_peering_hub_spoke2" {
  source              = "../../modules/vnet_peering"
  resource_group_name = azurerm_resource_group.rg.name
  hub_vnet_name       = module.vnet.vnet["hub"].name
  hub_vnet_id         = module.vnet.vnet["hub"].id
  spoke_vnet_name     = module.vnet.vnet["spoke2"].name
  spoke_vnet_id       = module.vnet.vnet["spoke2"].id
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

module "key_vault_secret" {
  source    = "../../modules/key_vault_secret"
  key_vault = module.key_vault.key_vault

  key_vault_secret = {
    target_key_vault = "app"
    secrets = {
      "SSH_PRIVATE_KEY"                            = module.ssh_public_key.private_key_pem
      "FUNCTION_STORAGE_ACCOUNT_CONNECTION_STRING" = module.storage.storage_account["func"].primary_connection_string
    }
  }
}

module "key_vault_certificate" {
  source        = "../../modules/key_vault_certificate"
  custom_domain = var.custom_domain
  key_vault     = module.key_vault.key_vault

  key_vault_certificate = {
    target_key_vault = "app"
    certificate_name = "self"
  }
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
  count = local.activity_log_enabled ? 1 : 0

  source                     = "../../modules/activity_log"
  log_analytics_workspace_id = module.log_analytics.log_analytics["logs"].id
  activity_log_categories    = toset(local.activity_log_categories)
}

module "dns_zone" {
  count = local.dns_zone_enabled ? 1 : 0

  source              = "../../modules/dns_zone"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  custom_domain       = var.custom_domain
}

module "private_dns_zone" {
  count = local.private_dns_zone_enabled ? 1 : 0

  source              = "../../modules/private_dns_zone"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  private_dns_zone    = var.private_dns_zone
  vnet                = module.vnet.vnet
  target_vnet         = "spoke1"
}

module "private_endpoint" {
  count = local.private_endpoint_enabled ? 1 : 0

  source              = "../../modules/private_endpoint"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  private_endpoint    = local.private_endpoint
}

module "private_link_scope" {
  source                      = "../../modules/private_link_scope"
  common                      = var.common
  resource_group_name         = azurerm_resource_group.rg.name
  tags                        = azurerm_resource_group.rg.tags
  private_link_scope          = var.private_link_scope
  private_link_scoped_service = local.private_link_scoped_service
}

module "frontdoor" {
  count = local.frontdoor_enabled ? 1 : 0

  source                 = "../../modules/frontdoor"
  common                 = var.common
  resource_group_name    = azurerm_resource_group.rg.name
  tags                   = azurerm_resource_group.rg.tags
  frontdoor_profile      = var.frontdoor_profile
  frontdoor_endpoint     = var.frontdoor_endpoint
  frontdoor_origin_group = var.frontdoor_origin_group
  frontdoor_origin       = var.frontdoor_origin
  frontdoor_route        = var.frontdoor_route
  dns_zone               = module.dns_zone[0].dns_zone
  custom_domain          = var.custom_domain

  backend_origins = {
    blob = {
      host_name          = module.storage.storage_account["app"].primary_blob_host
      origin_host_header = module.storage.storage_account["app"].primary_blob_host
    }
  }
}

module "frontdoor_waf" {
  count = local.frontdoor_waf_enabled ? 1 : 0

  source                         = "../../modules/frontdoor_waf"
  common                         = var.common
  resource_group_name            = azurerm_resource_group.rg.name
  tags                           = azurerm_resource_group.rg.tags
  frontdoor_security_policy      = var.frontdoor_security_policy
  frontdoor_firewall_policy      = var.frontdoor_firewall_policy
  frontdoor_firewall_custom_rule = var.frontdoor_firewall_custom_rule
  frontdoor_profile              = module.frontdoor[0].frontdoor_profile
  allowed_cidr                   = split(",", var.allowed_cidr)

  frontdoor_domain = concat(
    [for v in module.frontdoor[0].frontdoor_endpoint : v.id],
    [for v in module.frontdoor[0].frontdoor_custom_domain : v.id]
  )
}

module "container_registry" {
  count = local.container_registry_enabled ? 1 : 0

  source              = "../../modules/container_registry"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  random              = local.common.random
  container_registry  = var.container_registry
}

module "container_app_environment" {
  count = local.container_app_enabled ? 1 : 0

  source                    = "../../modules/container_app_environment"
  common                    = var.common
  resource_group_name       = azurerm_resource_group.rg.name
  tags                      = azurerm_resource_group.rg.tags
  container_app_environment = var.container_app_environment
  subnet                    = module.vnet.subnet
  log_analytics_workspace   = module.log_analytics.log_analytics
}

module "container_app" {
  count = local.container_app_enabled ? 1 : 0

  source                    = "../../modules/container_app"
  common                    = var.common
  resource_group_name       = azurerm_resource_group.rg.name
  tags                      = azurerm_resource_group.rg.tags
  container_app             = var.container_app
  allowed_cidr              = split(",", var.allowed_cidr)
  container_app_environment = module.container_app_environment[0].container_app_environment
  identity                  = module.user_assigned_identity.user_assigned_identity
  container_registry        = module.container_registry[0].container_registry
}

module "app_service_plan" {
  count = local.app_service_plan_enabled ? 1 : 0

  source              = "../../modules/app_service_plan"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  app_service_plan    = var.app_service_plan
}

module "app_service" {
  count = local.app_service_enabled ? 1 : 0

  source              = "../../modules/app_service"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  app_service         = var.app_service
  allowed_cidr        = split(",", var.allowed_cidr)
  app_service_plan    = module.app_service_plan[0].app_service_plan
  subnet              = module.vnet.subnet
  identity            = module.user_assigned_identity.user_assigned_identity
  frontdoor_profile   = module.frontdoor[0].frontdoor_profile

  app_settings = {
    app = {
      WEBSITE_PULL_IMAGE_OVER_VNET          = true
      APPLICATIONINSIGHTS_CONNECTION_STRING = module.application_insights.application_insights["app"].connection_string
    }
  }
  allowed_origins = {
    app = [
      "https://${module.frontdoor[0].frontdoor_endpoint["app"].host_name}",
      "https://${module.frontdoor[0].frontdoor_custom_domain["app"].host_name}",
      "https://localhost:3000",
    ]
  }
}

module "function" {
  count = local.function_enabled ? 1 : 0

  source               = "../../modules/function"
  common               = var.common
  resource_group_name  = azurerm_resource_group.rg.name
  tags                 = azurerm_resource_group.rg.tags
  function             = var.function
  allowed_cidr         = split(",", var.allowed_cidr)
  app_service_plan     = module.app_service_plan[0].app_service_plan
  subnet               = module.vnet.subnet
  application_insights = module.application_insights.application_insights
  identity             = module.user_assigned_identity.user_assigned_identity
  key_vault_secret     = module.key_vault_secret.key_vault_secret

  app_settings = {
    func = {
      WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
      WEBSITE_PULL_IMAGE_OVER_VNET        = true

      # マネージド ID を使用して Azure Storage に接続する場合
      # https://learn.microsoft.com/ja-jp/azure/azure-functions/functions-identity-based-connections-tutorial
      # AzureWebJobsStorage__accountName    = module.storage.storage_account["func"].name
    }
  }
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

module "document_intelligence" {
  source                = "../../modules/document_intelligence"
  common                = var.common
  resource_group_name   = azurerm_resource_group.rg.name
  tags                  = azurerm_resource_group.rg.tags
  document_intelligence = var.document_intelligence
  allowed_cidr          = split(",", var.allowed_cidr)
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

module "redis" {
  count = local.redis_enabled ? 1 : 0

  source              = "../../modules/redis"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  random              = local.common.random
  redis_cache         = var.redis_cache
}

module "ssh_public_key" {
  source              = "../../modules/ssh_public_key"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
}

module "vm" {
  count = local.vm_enabled ? 1 : 0

  source              = "../../modules/vm"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  vm                  = var.vm
  vm_admin_username   = var.vm_admin_username
  public_key          = module.ssh_public_key.public_key_openssh
  subnet              = module.vnet.subnet
}

module "vmss" {
  count = local.vmss_enabled ? 1 : 0

  source                                       = "../../modules/vmss"
  common                                       = var.common
  resource_group_name                          = azurerm_resource_group.rg.name
  tags                                         = azurerm_resource_group.rg.tags
  vmss                                         = var.vmss
  vmss_admin_username                          = var.vmss_admin_username
  public_key                                   = module.ssh_public_key.public_key_openssh
  subnet                                       = module.vnet.subnet
  application_gateway_backend_address_pool_ids = [tolist(module.application_gateway[0].application_gateway.backend_address_pool)[0].id]
}

module "loadbalancer" {
  count = local.vm_enabled ? 1 : 0

  source              = "../../modules/loadbalancer"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  loadbalancer        = var.loadbalancer
  network_interfaces  = module.vm[0].vm_network_interface
}

module "application_gateway" {
  count = local.vmss_enabled ? 1 : 0

  source               = "../../modules/application_gateway"
  common               = var.common
  resource_group_name  = azurerm_resource_group.rg.name
  tags                 = azurerm_resource_group.rg.tags
  application_gateway  = var.application_gateway
  subnet_id            = module.vnet.subnet["appgw"].id
  identity_id          = module.user_assigned_identity.user_assigned_identity["appgw"].id
  ssl_certificate_name = module.key_vault_certificate.key_vault_certificate["app"].name
  key_vault_secret_id  = module.key_vault_certificate.key_vault_certificate["app"].versionless_secret_id # シークレット識別子: https://{keyvault_name}.vault.azure.net/secretes/{certificate_name}/
}

module "bastion" {
  count = local.bastion_enabled ? 1 : 0

  source              = "../../modules/bastion"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  bastion             = var.bastion
  subnet              = module.vnet.subnet
}

module "nat_gateway" {
  count = local.nat_gateway_enabled ? 1 : 0

  source              = "../../modules/nat_gateway"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  nat_gateway         = var.nat_gateway
  subnet              = module.vnet.subnet
}

module "action_group" {
  source              = "../../modules/monitor_action_group"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  action_group        = var.action_group
}

module "resource_health_alert" {
  count = local.resource_health_alert_enabled ? 1 : 0

  source              = "../../modules/monitor_resource_health_alert"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  action_group        = module.action_group.action_group

  resource_health_alert = {
    target_action_group = "info",
    resource_ids = merge(
      { for k, v in module.storage.storage_account : v.name => v.id },
      { for k, v in module.key_vault.key_vault : v.name => v.id },
      # And more...
    )
  }
}

module "service_health_alert" {
  source               = "../../modules/monitor_service_health_alert"
  common               = var.common
  resource_group_name  = azurerm_resource_group.rg.name
  tags                 = azurerm_resource_group.rg.tags
  action_group         = module.action_group.action_group
  service_health_alert = var.service_health_alert
}

module "metric_alert" {
  source              = "../../modules/monitor_metric_alert"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  action_group        = module.action_group.action_group
  metric_alert        = local.metric_alert
}

module "activity_log_alert" {
  source              = "../../modules/monitor_activity_log_alert"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  action_group        = module.action_group.action_group
  activity_log_alert  = local.activity_log_alert
}

module "log_query_alert" {
  source              = "../../modules/monitor_log_query_alert"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  action_group        = module.action_group.action_group
  log_query_alert     = local.log_query_alert
}

module "diagnostic_setting" {
  count = local.diagnostic_setting_enabled ? 1 : 0

  source                  = "../../modules/diagnostic_setting"
  common                  = var.common
  log_analytics_workspace = module.log_analytics.log_analytics
  storage_account         = module.storage.storage_account

  diagnostic_setting = {
    target_log_analytics_workspace = "logs"
    target_storage_account         = "log"
    target_resources = merge(
      { for k, v in module.storage.storage_account : format("storage_account_%s", k) => v.id },
      { for k, v in module.storage.storage_account : format("blob_%s", k) => format("%s/blobServices/default", v.id) },
      { for k, v in module.key_vault.key_vault : format("key_vault_%s", k) => v.id },
      # And more...
    )
  }
}

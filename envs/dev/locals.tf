# Terraform を実行するアカウントの情報を取得する
data "azurerm_client_config" "current" {}

# # クライアントの IP アドレスを取得する
# data "http" "ipify" {
#   url = "http://api.ipify.org"
# }

locals {
  # 特定の Azure リソースを作成する/しない
  activity_log_enabled          = false
  dns_zone_enabled              = false
  private_dns_zone_enabled      = false
  private_endpoint_enabled      = false
  frontdoor_enabled             = false
  frontdoor_waf_enabled         = false
  container_registry_enabled    = false
  container_app_enabled         = false
  app_service_plan_enabled      = false
  app_service_enabled           = false
  function_enabled              = false
  aisearch_enabled              = false
  cosmosdb_enabled              = false
  mysql_enabled                 = false
  mssql_database_enabled        = false
  redis_enabled                 = false
  vm_enabled                    = false
  vmss_enabled                  = false
  loadbalancer_enabled          = false
  bastion_enabled               = false
  nat_gateway_enabled           = false
  resource_health_alert_enabled = false
  diagnostic_setting_enabled    = false
  defender_for_cloud_enabled    = false

  # 共通の変数
  common = {
    subscription_id = data.azurerm_client_config.current.subscription_id
    tenant_id       = data.azurerm_client_config.current.tenant_id
    random          = random_integer.num.result
    # client_ip_address = chomp(data.http.ipify.response_body)
    tags = {
      project = var.common.project
      env     = var.common.env
    }
  }

  # プライベートエンドポイント
  private_endpoint = merge(
    {
      for k, v in module.storage.storage_account :
      "storage_${k}" => {
        name                           = v.name
        subnet_id                      = module.vnet.subnet["pe"].id
        private_dns_zone_ids           = try([module.private_dns_zone[0].private_dns_zone["blob"].id], [])
        subresource_names              = ["blob"]
        private_connection_resource_id = v.id
      }
    },
    {
      for k, v in module.key_vault.key_vault :
      "kv_${k}" => {
        name                           = v.name
        subnet_id                      = module.vnet.subnet["pe"].id
        private_dns_zone_ids           = try([module.private_dns_zone[0].private_dns_zone["key_vault"].id], [])
        subresource_names              = ["vault"]
        private_connection_resource_id = v.id
      }
    },
    # Azure Monitor Private Link Scope (AMPLS) のプライベートエンドポイント
    {
      for k, v in module.private_link_scope.private_link_scope :
      "ampls_${k}" => {
        name      = v.name
        subnet_id = module.vnet.subnet["pe"].id
        private_dns_zone_ids = try([
          module.private_dns_zone[0].private_dns_zone["monitor"].id,
          module.private_dns_zone[0].private_dns_zone["oms"].id,
          module.private_dns_zone[0].private_dns_zone["ods"].id,
          module.private_dns_zone[0].private_dns_zone["agentsvc"].id,
        ], [])
        subresource_names              = ["azuremonitor"]
        private_connection_resource_id = v.id
      }
    }
  )

  # Azure Monitor Private Link Scope (AMPLS) にリンクするサービス
  private_link_scoped_service = merge(
    {
      for k, v in module.log_analytics.log_analytics :
      "log_${k}" => {
        name               = k
        linked_resource_id = v.id
        target_ampls       = "app"
      }
    },
    {
      for k, v in module.application_insights.application_insights :
      "appi_${k}" => {
        name               = k
        linked_resource_id = v.id
        target_ampls       = "app"
      }
    }
  )

  # アクティビティログのカテゴリ
  activity_log_categories = [
    "Administrative",
    "Security",
    "ServiceHealth",
    "Alert",
    "Recommendation",
    "Policy",
    "Autoscale",
    "ResourceHealth",
  ]

  # Azure ポータルの IP アドレス
  azure_portal_ips = {
    aisearch = "52.139.243.237"                                         # https://learn.microsoft.com/ja-jp/azure/search/service-configure-firewall
    cosmosdb = "13.91.105.215,4.210.172.107,13.88.56.148,40.91.218.243" # https://learn.microsoft.com/ja-jp/azure/cosmos-db/how-to-configure-firewall
  }

  # Alert Rule
  metric_alert = {
    "Microsoft.Storage/storageAccounts" = {
      resources = module.storage.storage_account
      metrics = [
        {
          enabled             = false
          metric_name         = "Availability"
          aggregation         = "Average"
          operator            = "LessThan"
          threshold           = 100
          frequency           = "PT1M"
          window_size         = "PT5M"
          severity            = 1
          target_action_group = "info"
        },
        {
          enabled             = false
          metric_name         = "UsedCapacity"
          aggregation         = "Average"
          operator            = "GreaterThan"
          threshold           = 80
          frequency           = "PT15M"
          window_size         = "PT1H"
          severity            = 3
          target_action_group = "info"
        },
      ]
    },
    "Microsoft.KeyVault/vaults" = {
      resources = module.key_vault.key_vault
      metrics = [
        {
          enabled             = false
          metric_name         = "Availability"
          aggregation         = "Average"
          operator            = "LessThan"
          threshold           = 100
          frequency           = "PT1M"
          window_size         = "PT5M"
          severity            = 1
          target_action_group = "info"
        },
        {
          enabled             = false
          metric_name         = "ServiceApiLatency"
          aggregation         = "Average"
          operator            = "GreaterThan"
          threshold           = 1000
          frequency           = "PT1M"
          window_size         = "PT5M"
          severity            = 2
          target_action_group = "info"
        },
      ]
    },
  }

  activity_log_alert = {
    "Microsoft.Storage/storageAccounts/delete" = {
      enabled     = false
      signal_name = "Delete Storage Accounts"
      scopes      = [azurerm_resource_group.rg.id]
      criteria = {
        category      = "Administrative"
        statuses      = ["Started"]
        resource_type = "Microsoft.Storage/storageAccounts"
      }
      target_action_group = "info"
    }
  }

  log_query_alert = {
    "RequestCountByCountry" = {
      enabled              = false
      severity             = 4
      evaluation_frequency = "PT10M"
      window_duration      = "PT10M"
      scope_id             = module.application_insights.application_insights["app"].id
      criteria = {
        query                   = <<-EOT
          requests
             | summarize CountByCountry=count() by client_CountryOrRegion
        EOT
        time_aggregation_method = "Maximum"
        metric_measure_column   = "CountByCountry" # time_aggregation_method が Average, Maximum, Minimum, Total の場合は集計対象の列を指定する。Count の場合は null を指定する。
        operator                = "LessThan"
        threshold               = 20
      }
      auto_mitigation_enabled          = true
      workspace_alerts_storage_enabled = false
      skip_query_validation            = false
      target_action_group              = "info"
    }
  }
}

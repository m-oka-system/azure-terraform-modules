# Terraform を実行するアカウントの情報を取得する
data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

# # クライアントの IP アドレスを取得する
# data "http" "ipify" {
#   url = "http://api.ipify.org"
# }

locals {
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

  # フェデレーション資格情報
  federated_identity_credential = {
    gha = {
      issuer    = "https://token.actions.githubusercontent.com"
      parent_id = module.user_assigned_identity.user_assigned_identity["gha"].id
      subject   = "repo:m-oka-system/azure-terraform-modules:environment:${var.common.env}"
    }
    k8s = {
      issuer    = module.kubernetes_cluster[0].kubernetes_cluster.oidc_issuer_url
      parent_id = module.user_assigned_identity.user_assigned_identity["k8s"].id
      subject   = "system:serviceaccount:default:${module.user_assigned_identity.user_assigned_identity["k8s"].name}"
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

  # Front Door に割り当てるカスタムドメインのマッピング
  frontdoor_custom_domain_mapping = {
    api   = "api-${var.common.env}"
    front = "www-${var.common.env}"
    web   = "static-${var.common.env}"
  }

  # Front Door の変数を動的に生成
  frontdoor_origins = merge(
    # App Service
    var.resource_enabled.app_service ? {
      for k, v in module.app_service[0].app_service : k => {
        host_name          = v.default_hostname
        origin_host_header = v.default_hostname
        subdomain          = lookup(local.frontdoor_custom_domain_mapping, k, "${k}-${var.common.env}")
      }
    } : {},
    # Storage (静的 Web サイト)
    {
      for k, v in module.storage.storage_account : k => {
        host_name          = v.primary_web_host
        origin_host_header = v.primary_web_host
        subdomain          = lookup(local.frontdoor_custom_domain_mapping, k, "${k}-${var.common.env}")
      } if k == "web"
    }
  )

  # キャッシュを有効化するオリジンの key 一覧
  cached_origin_keys = ["front", "web"]

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

################################
# Web App for Containers
################################
resource "azurerm_linux_web_app" "this" {
  for_each                                       = var.app_service
  name                                           = "webapp-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name                            = var.resource_group_name
  location                                       = var.common.location
  service_plan_id                                = var.app_service_plan[each.value.target_service_plan].id
  virtual_network_subnet_id                      = var.subnet[each.value.target_subnet].id
  ftp_publish_basic_authentication_enabled       = false # FTP 基本認証を無効化
  webdeploy_publish_basic_authentication_enabled = false # SCM 基本認証を無効化
  https_only                                     = true  # HTTPS のみ
  vnet_image_pull_enabled                        = true  # VNet 統合を経由してコンテナーイメージをプル
  public_network_access_enabled                  = each.value.public_network_access_enabled
  key_vault_reference_identity_id                = var.identity[each.value.target_user_assigned_identity].id

  identity {
    type = "UserAssigned"
    identity_ids = [
      var.identity[each.value.target_user_assigned_identity].id
    ]
  }

  app_settings = var.app_settings[each.key]

  site_config {
    always_on                         = true       # Always On を有効化
    ftps_state                        = "Disabled" # FTP の状態を無効化
    http2_enabled                     = true       # HTTP/2 を有効化
    vnet_route_all_enabled            = true       # VNet 経由でルーティング
    scm_use_main_ip_restriction       = false      # メインサイトのルールを使用しない
    ip_restriction_default_action     = "Deny"     # メインサイトの一致しないルールのデフォルトアクション
    scm_ip_restriction_default_action = "Deny"     # 高度なツールサイト(SCM)の一致しないルールのデフォルトアクション
    minimum_tls_version               = "1.2"      # メインサイトの最小 TLS バージョン
    scm_minimum_tls_version           = "1.2"      # 高度なツールサイト(SCM)の最小 TLS バージョン

    container_registry_use_managed_identity       = true # ACR 認証にマネージド ID を使用
    container_registry_managed_identity_client_id = var.identity[each.value.target_user_assigned_identity].client_id


    dynamic "cors" {
      for_each = each.value.site_config.cors != null ? [true] : []

      content {
        allowed_origins     = var.allowed_origins[each.key]
        support_credentials = each.value.site_config.cors.support_credentials
      }
    }

    dynamic "ip_restriction" {
      for_each = each.value.ip_restriction

      content {
        name        = ip_restriction.value.name
        priority    = ip_restriction.value.priority
        action      = ip_restriction.value.action
        ip_address  = lookup(ip_restriction.value, "ip_address", null) == "MyIP" ? join(",", [for ip in var.allowed_cidr : "${ip}/32"]) : lookup(ip_restriction.value, "ip_address", null)
        service_tag = ip_restriction.value.service_tag

        dynamic "headers" {
          for_each = var.frontdoor_profile != null && ip_restriction.key == "frontdoor" ? [true] : []

          content {
            x_azure_fdid = [
              var.frontdoor_profile.resource_guid
            ]
            x_fd_health_probe = []
            x_forwarded_for   = []
            x_forwarded_host  = []
          }
        }
      }
    }

    dynamic "scm_ip_restriction" {
      for_each = each.value.scm_ip_restriction

      content {
        name        = scm_ip_restriction.value.name
        priority    = scm_ip_restriction.value.priority
        action      = scm_ip_restriction.value.action
        ip_address  = lookup(scm_ip_restriction.value, "ip_address", null) == "MyIP" ? join(",", [for ip in var.allowed_cidr : "${ip}/32"]) : lookup(scm_ip_restriction.value, "ip_address", null)
        service_tag = scm_ip_restriction.value.service_tag
      }
    }

    application_stack {
      # Initial container image (overwritten by CI/CD)
      docker_image_name   = "appsvc/staticsite:latest"
      docker_registry_url = "https://mcr.microsoft.com"
    }
  }

  lifecycle {
    ignore_changes = [
      site_config[0].application_stack[0].docker_image_name,
      site_config[0].application_stack[0].docker_registry_url,
      tags["hidden-link: /app-insights-conn-string"],
      tags["hidden-link: /app-insights-instrumentation-key"],
      tags["hidden-link: /app-insights-resource-id"],
    ]
  }

  tags = var.tags
}

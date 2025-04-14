################################
# Diagnostic setting
################################
data "azurerm_monitor_diagnostic_categories" "this" {
  for_each    = var.diagnostic_setting.target_resources
  resource_id = each.value
}

locals {
  providers_with_dedicated_log_type = [
    "Microsoft.DocumentDB"
  ]
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each                   = var.diagnostic_setting.target_resources
  name                       = replace("${each.key}-${var.common.project}-${var.common.env}-diag-setting", "_", "-")
  target_resource_id         = each.value
  log_analytics_workspace_id = var.log_analytics_workspace[var.diagnostic_setting.target_log_analytics_workspace].id
  storage_account_id         = var.storage_account[var.diagnostic_setting.target_storage_account].id

  # 診断設定の対象リソースが、専用の Log Analytics テーブルを持つリソースタイプ (local.providers_with_dedicated_log_type リスト内の正規表現パターンに一致するか) を判定する
  # もし一致する場合 (リストの長さ > 0)、ログの送信先タイプとして "Dedicated" を設定し、リソースタイプ固有の専用テーブルにログを送信する
  # 一致しない場合は null を設定し、デフォルトで共通の AzureDiagnostics テーブルに送信されるようにする
  log_analytics_destination_type = length([for provider in local.providers_with_dedicated_log_type : provider if can(regex(provider, each.value))]) > 0 ? "Dedicated" : null

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.this[each.key].log_category_types

    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.this[each.key].metrics

    content {
      category = metric.value
      enabled  = true
    }
  }
}

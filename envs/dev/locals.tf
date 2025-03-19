# Terraform を実行するアカウントの情報を取得する
data "azurerm_client_config" "current" {}

# クライアントの IP アドレスを取得する
data "http" "ipify" {
  url = "http://api.ipify.org"
}

locals {
  # 特定の Azure リソースを作成する/しない
  aisearch_enabled = false
  cosmosdb_enabled = false
  mysql_enabled    = false
  redis_enabled    = false

  # 共通の変数
  common = {
    subscription_id   = data.azurerm_client_config.current.subscription_id
    tenant_id         = data.azurerm_client_config.current.tenant_id
    random            = random_integer.num.result
    client_ip_address = chomp(data.http.ipify.response_body)
    tags = {
      project = var.common.project
      env     = var.common.env
    }
  }

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
}

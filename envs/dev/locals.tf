# Terraform を実行するアカウントの情報を取得する
data "azurerm_client_config" "current" {}

# クライアントの IP アドレスを取得する
data "http" "ipify" {
  url = "http://api.ipify.org"
}

locals {
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
}

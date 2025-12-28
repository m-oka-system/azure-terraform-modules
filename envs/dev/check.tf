################################
# Network security group
################################

# var.network_security_rule から各 NSG のルール数を動的に計算
# これにより、ハードコードが不要になり、Terraform 定義と Azure 実際の状態を比較できる
locals {
  # 各 NSG に紐づくセキュリティルール数を var.network_security_rule から計算
  nsg_expected_rule_count = {
    for k in keys(var.network_security_group) :
    k => length([
      for v in var.network_security_rule :
      v if v.target_nsg == k
    ])
  }
}

# 各 NSG の実際の情報を Azure から取得
data "azurerm_network_security_group" "this" {
  for_each            = var.network_security_group
  name                = module.network_security_group.network_security_group[each.key].name
  resource_group_name = azurerm_resource_group.rg.name
  depends_on          = [module.network_security_group]
}

# NSG のセキュリティルール数を検証（Terraform 定義 vs Azure 実際の状態）
check "network_security_group_rule_count" {
  assert {
    condition = alltrue([
      for k, v in local.nsg_expected_rule_count :
      length(data.azurerm_network_security_group.this[k].security_rule) == v
    ])
    error_message = "NSG のルール数が Terraform 定義と Azure 実際の状態で一致しません（ドリフト検知）:\n${join("\n", [
      for k, v in local.nsg_expected_rule_count :
      "- ${k}: Terraform定義=${v}, Azure実際=${length(data.azurerm_network_security_group.this[k].security_rule)}"
      if length(data.azurerm_network_security_group.this[k].security_rule) != v
    ])}"
  }
}

################################
# Front Door Security Headers
################################

# Front Door のカスタムドメインに対してセキュリティヘッダーを検証
# 検証対象: ステータスコード 200、セキュリティヘッダー（HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy）
# 注: check ブロック内の data ソースはエラー時に Warning として扱われるため、各エンドポイントごとに check を定義
locals {
  frontdoor_expected_security_headers = keys(var.frontdoor_security_headers)

  frontdoor_custom_domain_urls = var.resource_enabled.frontdoor && var.resource_enabled.custom_domain ? {
    for k, v in module.frontdoor[0].frontdoor_custom_domain : k => "https://${v.host_name}"
  } : {}
}

check "frontdoor_api_security_headers" {
  data "http" "api" {
    url = local.frontdoor_custom_domain_urls["api"]
  }

  assert {
    condition     = data.http.api.status_code == 200
    error_message = "api (${local.frontdoor_custom_domain_urls["api"]}): status=${data.http.api.status_code}"
  }

  assert {
    condition = alltrue([
      for k in local.frontdoor_expected_security_headers :
      contains(keys(data.http.api.response_headers), k)
    ])
    error_message = "api: 不足=[${join(", ", [
      for k in local.frontdoor_expected_security_headers :
      k if !contains(keys(data.http.api.response_headers), k)
    ])}]"
  }
}

check "frontdoor_front_security_headers" {
  data "http" "front" {
    url = local.frontdoor_custom_domain_urls["front"]
  }

  assert {
    condition     = data.http.front.status_code == 200
    error_message = "front (${local.frontdoor_custom_domain_urls["front"]}): status=${data.http.front.status_code}"
  }

  assert {
    condition = alltrue([
      for k in local.frontdoor_expected_security_headers :
      contains(keys(data.http.front.response_headers), k)
    ])
    error_message = "front: 不足=[${join(", ", [
      for k in local.frontdoor_expected_security_headers :
      k if !contains(keys(data.http.front.response_headers), k)
    ])}]"
  }
}

check "frontdoor_web_security_headers" {
  data "http" "web" {
    url = local.frontdoor_custom_domain_urls["web"]
  }

  assert {
    condition     = data.http.web.status_code == 200
    error_message = "web (${local.frontdoor_custom_domain_urls["web"]}): status=${data.http.web.status_code}"
  }

  assert {
    condition = alltrue([
      for k in local.frontdoor_expected_security_headers :
      contains(keys(data.http.web.response_headers), k)
    ])
    error_message = "web: 不足=[${join(", ", [
      for k in local.frontdoor_expected_security_headers :
      k if !contains(keys(data.http.web.response_headers), k)
    ])}]"
  }
}

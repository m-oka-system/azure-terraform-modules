################################
# Front Door
################################
resource "azurerm_cdn_frontdoor_profile" "this" {
  name                     = "afd-${var.common.project}-${var.common.env}"
  resource_group_name      = var.resource_group_name
  sku_name                 = var.frontdoor_profile.sku_name
  response_timeout_seconds = var.frontdoor_profile.response_timeout_seconds

  tags = var.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = "afd-ep-${var.common.project}-${var.common.env}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  for_each                 = var.frontdoor_origins
  name                     = "afd-origin-group-${each.key}-${var.common.project}-${var.common.env}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  session_affinity_enabled = false # セッションアフィニティを無効にする

  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 10 # トラフィックを別のエンドポイントに切り替えるまでの経過時間 (現在は使用されていない)

  health_probe {
    interval_in_seconds = 100     # 正常性プローブの間隔 (秒)
    path                = "/"     # 正常性プローブのパス
    protocol            = "Https" # 正常性プローブのプロトコル
    request_type        = "HEAD"  # 正常性プローブのリクエストタイプ
  }

  load_balancing {
    additional_latency_in_milliseconds = 50 # 待機時間感度 (ミリ秒)
    sample_size                        = 4  # サンプルサイズ
    successful_samples_required        = 3  # 成功したサンプル数
  }
}

resource "azurerm_cdn_frontdoor_origin" "this" {
  for_each                      = var.frontdoor_origins
  name                          = "afd-origin-${each.key}-${var.common.project}-${var.common.env}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this[each.key].id
  enabled                       = true

  certificate_name_check_enabled = true # 証明書のサブジェクト名の検証を有効にする

  host_name          = each.value.host_name
  http_port          = 80
  https_port         = 443
  origin_host_header = each.value.origin_host_header
  priority           = 1
  weight             = 1000
}

resource "azurerm_cdn_frontdoor_route" "this" {
  for_each                      = var.frontdoor_routes
  name                          = "afd-route-${each.key}-${var.common.project}-${var.common.env}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this[each.key].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.this[each.key].id]
  cdn_frontdoor_rule_set_ids    = []
  enabled                       = true

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  # ルートにカスタムドメインを関連付ける
  cdn_frontdoor_custom_domain_ids = try([azurerm_cdn_frontdoor_custom_domain.this[each.key].id], [])
  link_to_default_domain          = false

  dynamic "cache" {
    for_each = lookup(each.value, "cache", null) != null ? [each.value.cache] : []

    content {
      compression_enabled           = cache.value.compression_enabled
      query_string_caching_behavior = cache.value.query_string_caching_behavior
      query_strings                 = cache.value.query_strings
      content_types_to_compress     = cache.value.content_types_to_compress
    }
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "this" {
  for_each                 = var.frontdoor_custom_domains
  name                     = replace("${each.value.subdomain}.${var.dns_zone.name}", ".", "-")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  dns_zone_id              = var.dns_zone.id
  host_name                = "${each.value.subdomain}.${var.dns_zone.name}"

  tls {
    certificate_type = "ManagedCertificate"
  }
}

resource "azurerm_dns_txt_record" "afd_validation" {
  for_each            = var.frontdoor_custom_domains
  name                = "_dnsauth.${each.value.subdomain}"
  zone_name           = var.dns_zone.name
  resource_group_name = var.dns_zone.resource_group_name
  ttl                 = 3600

  record {
    value = azurerm_cdn_frontdoor_custom_domain.this[each.key].validation_token
  }
}

resource "azurerm_dns_cname_record" "afd_cname" {
  for_each            = var.frontdoor_custom_domains
  name                = each.value.subdomain
  zone_name           = var.dns_zone.name
  resource_group_name = var.dns_zone.resource_group_name
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.this.host_name
}

# azurerm_cdn_frontdoor_custom_domain_association は不要
# ルートにカスタムドメインを関連付けるためのものではない
# ルートにカスタムドメインが関連付けられている前提で、関連付けを解除したり、再登録するときに使用する模様
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain_association

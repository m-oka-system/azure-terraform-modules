################################
# Front Door
################################

locals {
  # キャッシュで圧縮するコンテンツタイプの標準リスト
  cache_compression_content_types = [
    "application/eot",
    "application/font",
    "application/font-sfnt",
    "application/javascript",
    "application/json",
    "application/opentype",
    "application/otf",
    "application/pkcs7-mime",
    "application/truetype",
    "application/ttf",
    "application/vnd.ms-fontobject",
    "application/xhtml+xml",
    "application/xml",
    "application/xml+rss",
    "application/x-font-opentype",
    "application/x-font-truetype",
    "application/x-font-ttf",
    "application/x-httpd-cgi",
    "application/x-javascript",
    "application/x-mpegurl",
    "application/x-opentype",
    "application/x-otf",
    "application/x-perl",
    "application/x-ttf",
    "font/eot",
    "font/ttf",
    "font/otf",
    "font/opentype",
    "image/svg+xml",
    "text/css",
    "text/csv",
    "text/html",
    "text/javascript",
    "text/js",
    "text/plain",
    "text/richtext",
    "text/tab-separated-values",
    "text/xml",
    "text/x-script",
    "text/x-component",
    "text/x-java-source",
  ]
}

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

  tags = var.tags
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
  for_each                      = var.frontdoor_origins
  name                          = "afd-route-${each.key}-${var.common.project}-${var.common.env}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this[each.key].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.this[each.key].id]
  cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.this.id]
  enabled                       = true

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  # ルートにカスタムドメインを関連付ける
  cdn_frontdoor_custom_domain_ids = try([azurerm_cdn_frontdoor_custom_domain.this[each.key].id], [])
  link_to_default_domain          = false

  # キャッシュ設定：cached_origin_keys に含まれるオリジンのルートでキャッシュを有効化
  dynamic "cache" {
    for_each = contains(var.cached_origin_keys, each.key) ? [true] : []

    content {
      compression_enabled           = true
      query_string_caching_behavior = "IgnoreQueryString"
      query_strings                 = []
      content_types_to_compress     = local.cache_compression_content_types
    }
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "this" {
  for_each                 = var.dns_zone != null ? var.frontdoor_origins : {}
  name                     = replace("${each.value.subdomain}.${var.dns_zone.name}", ".", "-")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  dns_zone_id              = var.dns_zone.id
  host_name                = "${each.value.subdomain}.${var.dns_zone.name}"

  tls {
    certificate_type = "ManagedCertificate"
  }
}

resource "azurerm_dns_txt_record" "afd_validation" {
  for_each            = var.dns_zone != null ? var.frontdoor_origins : {}
  name                = "_dnsauth.${each.value.subdomain}"
  zone_name           = var.dns_zone.name
  resource_group_name = var.dns_zone.resource_group_name
  ttl                 = 3600

  record {
    value = azurerm_cdn_frontdoor_custom_domain.this[each.key].validation_token
  }

  tags = var.tags
}

resource "azurerm_dns_cname_record" "afd_cname" {
  for_each            = var.dns_zone != null ? var.frontdoor_origins : {}
  name                = each.value.subdomain
  zone_name           = var.dns_zone.name
  resource_group_name = var.dns_zone.resource_group_name
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.this.host_name

  tags = var.tags
}

# azurerm_cdn_frontdoor_custom_domain_association は不要
# ルートにカスタムドメインを関連付けるためのものではない
# ルートにカスタムドメインが関連付けられている前提で、関連付けを解除したり、再登録するときに使用する模様
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain_association

# セキュリティヘッダーを追加するためのルールセット
resource "azurerm_cdn_frontdoor_rule_set" "this" {
  name                     = "SecurityHeaders"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
}

resource "azurerm_cdn_frontdoor_rule" "this" {
  name                      = "AddSecurityHeaders"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.this.id
  order                     = 1
  behavior_on_match         = "Continue"

  actions {
    dynamic "response_header_action" {
      for_each = var.frontdoor_security_headers

      content {
        header_action = response_header_action.value.action
        header_name   = response_header_action.key
        value         = response_header_action.value.action != "Delete" ? response_header_action.value.value : null
      }
    }
  }

  depends_on = [
    azurerm_cdn_frontdoor_origin_group.this,
    azurerm_cdn_frontdoor_origin.this
  ]
}

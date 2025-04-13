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
  for_each                 = var.frontdoor_endpoint
  name                     = "afd-ep-${each.value.name}-${var.common.project}-${var.common.env}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  for_each                 = var.frontdoor_origin_group
  name                     = "afd-origin-group-${each.value.name}-${var.common.project}-${var.common.env}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  session_affinity_enabled = each.value.session_affinity_enabled

  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = each.value.restore_traffic_time_to_healed_or_new_endpoint_in_minutes

  health_probe {
    interval_in_seconds = each.value.health_probe.interval_in_seconds
    path                = each.value.health_probe.path
    protocol            = each.value.health_probe.protocol
    request_type        = each.value.health_probe.request_type
  }

  load_balancing {
    additional_latency_in_milliseconds = each.value.load_balancing.additional_latency_in_milliseconds
    sample_size                        = each.value.load_balancing.sample_size
    successful_samples_required        = each.value.load_balancing.successful_samples_required
  }
}

resource "azurerm_cdn_frontdoor_origin" "this" {
  for_each                      = var.frontdoor_origin
  name                          = "afd-origin-${each.value.name}-${var.common.project}-${var.common.env}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this[each.value.target_frontdoor_origin_group].id
  enabled                       = true

  certificate_name_check_enabled = true

  host_name          = var.backend_origins[each.value.target_backend_origin].host_name
  http_port          = each.value.http_port
  https_port         = each.value.https_port
  origin_host_header = var.backend_origins[each.value.target_backend_origin].origin_host_header
  priority           = each.value.priority
  weight             = each.value.weight
}

resource "azurerm_cdn_frontdoor_route" "this" {
  for_each                      = var.frontdoor_route
  name                          = "afd-route-${each.value.name}-${var.common.project}-${var.common.env}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this[each.value.target_frontdoor_endpoint].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this[each.value.target_frontdoor_origin_group].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.this[each.value.target_frontdoor_origin].id]
  cdn_frontdoor_rule_set_ids    = []
  enabled                       = true

  forwarding_protocol    = each.value.forwarding_protocol
  https_redirect_enabled = each.value.https_redirect_enabled
  patterns_to_match      = each.value.patterns_to_match
  supported_protocols    = each.value.supported_protocols

  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.this[each.value.target_custom_domain].id]
  link_to_default_domain          = each.value.link_to_default_domain

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
  for_each                 = var.custom_domain
  name                     = replace("${var.custom_domain[each.key].subdomain}.${var.custom_domain[each.key].dns_zone_name}", ".", "-")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  dns_zone_id              = var.dns_zone[each.key].id
  host_name                = "${var.custom_domain[each.key].subdomain}.${var.custom_domain[each.key].dns_zone_name}"

  tls {
    certificate_type = "ManagedCertificate"
  }
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "this" {
  for_each                       = var.custom_domain
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.this[each.key].id
  cdn_frontdoor_route_ids = [
    # カスタムドメイン の key と ルートの target_custom_domain をマッピングして、関連付けるルート ID を取得
    for k, v in var.frontdoor_route : azurerm_cdn_frontdoor_route.this[k].id if v.target_custom_domain == each.key
  ]
}

resource "azurerm_dns_txt_record" "afd_validation" {
  for_each            = var.custom_domain
  name                = "_dnsauth.${each.value.subdomain}"
  zone_name           = var.dns_zone[each.key].name
  resource_group_name = var.resource_group_name
  ttl                 = 3600

  record {
    value = azurerm_cdn_frontdoor_custom_domain.this[each.key].validation_token
  }
}

resource "azurerm_dns_cname_record" "afd_cname" {
  for_each            = var.custom_domain
  name                = each.value.subdomain
  zone_name           = var.dns_zone[each.key].name
  resource_group_name = var.resource_group_name
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.this[each.value.target_frontdoor_endpoint].host_name
}

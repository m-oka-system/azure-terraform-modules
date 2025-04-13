################################
# Web Application Firewall (WAF)
################################
resource "azurerm_cdn_frontdoor_security_policy" "this" {
  for_each                 = var.frontdoor_security_policy
  name                     = "afd-secpolicy-${each.value.name}-${var.common.project}-${var.common.env}"
  cdn_frontdoor_profile_id = var.frontdoor_profile.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.this[each.value.target_firewall_policy].id

      association {
        dynamic "domain" {
          for_each = toset(var.frontdoor_domain)

          content {
            cdn_frontdoor_domain_id = domain.value
          }
        }

        patterns_to_match = each.value.patterns_to_match
      }
    }
  }
}

resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  for_each                          = var.frontdoor_firewall_policy
  name                              = each.value.name
  resource_group_name               = var.resource_group_name
  sku_name                          = each.value.sku_name
  enabled                           = true
  mode                              = each.value.mode
  custom_block_response_status_code = each.value.custom_block_response_status_code

  dynamic "custom_rule" {
    for_each = { for k, v in var.frontdoor_firewall_custom_rule : k => v if v.target_firewall_policy == each.key }

    content {
      name     = custom_rule.key
      enabled  = true
      priority = custom_rule.value.priority
      type     = custom_rule.value.type
      action   = custom_rule.value.action

      match_condition {
        match_variable     = custom_rule.value.match_condition.match_variable
        operator           = custom_rule.value.match_condition.operator
        negation_condition = custom_rule.value.match_condition.negation_condition
        match_values       = join(",", lookup(custom_rule.value.match_condition, "match_values", null)) == "MyIP" ? var.allowed_cidr : lookup(custom_rule.value.match_condition, "match_values", null)
      }
    }
  }

  tags = var.tags
}

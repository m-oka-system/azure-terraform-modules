################################
# Web Application Firewall (WAF)
################################
locals {
  # Front Door Profile の SKU を判定 （Premium のみマネージドルールをサポート）
  is_premium_sku = var.frontdoor_profile.sku_name == "Premium_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_security_policy" "this" {
  for_each                 = var.frontdoor_firewall_policy
  name                     = "afd-secpolicy-${each.key}-${var.common.project}-${var.common.env}"
  cdn_frontdoor_profile_id = var.frontdoor_profile.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.this[each.key].id

      association {
        # 各セキュリティポリシーに対して 1 つのカスタムドメインを関連付ける
        # アーキテクチャ: セキュリティポリシーとカスタムドメインを 1 対 1 でマッピングし、ドメインごとに異なる WAF 設定（カスタムルール、マネージドルール）を適用可能にする
        domain {
          cdn_frontdoor_domain_id = var.frontdoor_custom_domain[each.key].id
        }

        patterns_to_match = ["/*"]
      }
    }
  }
}

resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  for_each            = var.frontdoor_firewall_policy
  name                = replace("wafpolicy-${each.key}-${var.common.project}-${var.common.env}", "-", "")
  resource_group_name = var.resource_group_name
  sku_name            = var.frontdoor_profile.sku_name
  mode                = each.value.mode
  enabled             = lookup(each.value, "enabled", true)

  # ポリシー設定
  request_body_check_enabled                = lookup(each.value, "request_body_check_enabled", true)       # 要求本文の検査を有効にする
  redirect_url                              = lookup(each.value, "redirect_url", null)                     # リダイレクトURL
  custom_block_response_status_code         = lookup(each.value, "custom_block_response_status_code", 403) # ブロック時の応答ステータスコード （200, 403, 405, 406, 429）
  custom_block_response_body                = lookup(each.value, "custom_block_response_body", null)       # ブロック時のカスタム応答ボディ （Base64エンコード形式）
  js_challenge_cookie_expiration_in_minutes = local.is_premium_sku ? 30 : null                             # JavaScript チャレンジ Cookie の有効期限（5～1440分、デフォルト: 30分）
  captcha_cookie_expiration_in_minutes      = local.is_premium_sku ? 30 : null                             # Captcha チャレンジ Cookie の有効期限（5～1440分、デフォルト: 30分）

  # カスタムルール
  dynamic "custom_rule" {
    for_each = lookup(each.value, "custom_rules", [])

    content {
      name     = custom_rule.value.name     # ルール名（ポリシー内で一意）
      enabled  = true                       # ルールの有効/無効（デフォルト: true）
      type     = custom_rule.value.type     # ルールタイプ: MatchRule または RateLimitRule
      priority = custom_rule.value.priority # 優先度（小さい値ほど先に評価される、デフォルト: 1）
      action   = custom_rule.value.action   # アクション: Allow, Block, Log, Redirect, JSChallenge, CAPTCHA

      # レート制限設定 (type が RateLimitRule の場合に使用)
      rate_limit_duration_in_minutes = lookup(custom_rule.value, "rate_limit_duration_in_minutes", null) # レート制限の期間 （分、デフォルト: 1）
      rate_limit_threshold           = lookup(custom_rule.value, "rate_limit_threshold", null)           # レート制限の閾値 （リクエスト数、デフォルト: 10）

      # マッチ条件 （最大10個まで定義可能）
      dynamic "match_condition" {
        for_each = custom_rule.value.match_conditions

        content {
          match_variable     = match_condition.value.match_variable                      # マッチ対象変数: Cookies, PostArgs, QueryString, RemoteAddr, RequestBody, RequestHeader, RequestMethod, RequestUri, SocketAddr
          match_values       = match_condition.value.match_values                        # マッチ値（最大600個まで、全体で最大600個）
          operator           = match_condition.value.operator                            # 比較演算子: Any, BeginsWith, Contains, EndsWith, Equal, GeoMatch, GreaterThan, GreaterThanOrEqual, IPMatch, LessThan, LessThanOrEqual, RegEx
          selector           = lookup(match_condition.value, "selector", null)           # セレクター（match_variable が QueryString, PostArgs, RequestHeader, Cookies の場合に特定のキーを指定）
          negation_condition = lookup(match_condition.value, "negation_condition", null) # 条件の否定 （マッチ結果を反転させる）
          transforms         = lookup(match_condition.value, "transforms", null)         # 変換処理 （最大5個まで適用可能） Lowercase, RemoveNulls, Trim, Uppercase, URLDecode, URLEncode
        }
      }
    }
  }

  # マネージドルール
  # Azureが提供するマネージドルールセットを適用 （Premium SKUのみ）
  dynamic "managed_rule" {
    for_each = local.is_premium_sku ? lookup(each.value, "managed_rules", []) : []

    content {
      type    = managed_rule.value.type    # マネージドルールタイプ: DefaultRuleSet, Microsoft_DefaultRuleSet, BotProtection, Microsoft_BotManagerRuleSet
      version = managed_rule.value.version # バージョン
      action  = managed_rule.value.action  # デフォルトアクション: Allow, Log, Block, Redirect

      # 除外設定（特定の条件を検査から除外）
      dynamic "exclusion" {
        for_each = lookup(managed_rule.value, "exclusions", [])

        content {
          match_variable = exclusion.value.match_variable # 除外対象変数: QueryStringArgNames, RequestBodyPostArgNames, RequestCookieNames, RequestHeaderNames, RequestBodyJsonArgNames
          operator       = exclusion.value.operator       # 演算子: Equals, Contains, StartsWith, EndsWith, EqualsAny
          selector       = exclusion.value.selector       # セレクター （operator が EqualsAny の場合は "*" を指定）
        }
      }

      # ルールグループのオーバーライド設定
      dynamic "override" {
        for_each = lookup(managed_rule.value, "overrides", [])

        content {
          rule_group_name = override.value.rule_group_name

          # ルールグループレベルの除外設定
          dynamic "exclusion" {
            for_each = lookup(override.value, "exclusions", [])

            content {
              match_variable = exclusion.value.match_variable
              operator       = exclusion.value.operator
              selector       = exclusion.value.selector
            }
          }

          # 個別ルールのオーバーライド
          dynamic "rule" {
            for_each = lookup(override.value, "rules", [])

            content {
              rule_id = rule.value.rule_id                   # マネージドルールID
              enabled = lookup(rule.value, "enabled", false) # ルールの有効/無効（デフォルト: false）
              action  = rule.value.action                    # アクション: Allow, CAPTCHA, Log, Block, Redirect, AnomalyScoring, JSChallenge

              # ルールレベルの除外設定
              dynamic "exclusion" {
                for_each = lookup(rule.value, "exclusions", [])

                content {
                  match_variable = exclusion.value.match_variable
                  operator       = exclusion.value.operator
                  selector       = exclusion.value.selector
                }
              }
            }
          }
        }
      }
    }
  }

  # ログのスクラブ (機密データ保護)
  dynamic "log_scrubbing" {
    for_each = lookup(each.value, "log_scrubbing_enabled", false) ? [true] : []

    content {
      enabled = true

      # スクラビングルール（ログからマスクする対象を定義）
      dynamic "scrubbing_rule" {
        for_each = lookup(each.value, "scrubbing_rules", [])

        content {
          enabled        = lookup(scrubbing_rule.value, "enabled", true)      # ルールの有効/無効 （デフォルト: true）
          match_variable = scrubbing_rule.value.match_variable                # マスク対象変数: QueryStringArgNames, RequestBodyJsonArgNames, RequestBodyPostArgNames, RequestCookieNames, RequestHeaderNames, RequestIPAddress, RequestUri
          operator       = lookup(scrubbing_rule.value, "operator", "Equals") # 演算子: Equals, EqualsAny （デフォルト: Equals）
          selector       = lookup(scrubbing_rule.value, "selector", null)     # セレクター（operator が EqualsAny の場合は指定不可）
        }
      }
    }
  }

  tags = var.tags
}

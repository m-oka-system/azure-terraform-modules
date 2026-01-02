# ================================================================================
# Azure Storage Module Tests
# ================================================================================
# このテストファイルは、dev 環境のストレージモジュールの動作を検証します。
# dev/variables.tf のデフォルト値と dev/terraform.tfvars を使用してテストします。
# ================================================================================

# ================================================================================
# Test 1: dev 環境のデフォルト設定を検証
# ================================================================================
# 目的: variables.tf で定義されているデフォルトのリソース構成をテスト
# 注: セキュリティ設定は Test 8 (security_best_practices) で検証
run "default_dev_configuration" {
  command = plan

  # variables ブロックを省略 → dev/variables.tf のデフォルト値を使用

  # 4つのストレージアカウント（app, web, func, log）が作成される
  assert {
    condition     = length(module.storage.storage_account) == 4
    error_message = "デフォルトでは4つのストレージアカウント（app, web, func, log）が作成されるべきです"
  }

  # web ストレージアカウントの Static Website が有効
  assert {
    condition     = length(module.storage.storage_static_website) == 1
    error_message = "web アカウント用に Static Website が作成されるべきです（詳細は Test 3 で検証）"
  }

  # デフォルトの Blob コンテナが作成される
  assert {
    condition     = length(module.storage.storage_container) == 2
    error_message = "デフォルトでは2つの Blob コンテナ（app_static, app_media）が作成されるべきです（詳細は Test 6 で検証）"
  }

  # 注: ライフサイクルポリシーの検証は Test 7 (storage_management_policy_configuration) で実施
}

# ================================================================================
# Test 2: app ストレージアカウントの詳細検証
# ================================================================================
# 目的: app アカウントのセキュリティとデータ保護設定を確認
run "app_storage_security_and_protection" {
  command = plan

  # app アカウントのネットワークルール検証
  assert {
    condition     = length(module.storage.storage_account["app"].network_rules) > 0
    error_message = "app アカウントはネットワークルールを設定すべきです"
  }

  assert {
    condition     = module.storage.storage_account["app"].network_rules[0].default_action == "Deny"
    error_message = "app アカウントのネットワークルールはデフォルトで Deny にすべきです"
  }

  assert {
    condition     = contains(module.storage.storage_account["app"].network_rules[0].bypass, "AzureServices")
    error_message = "app アカウントは Azure サービスからのアクセスを許可すべきです"
  }

  # Blob の削除保持ポリシー
  assert {
    condition     = module.storage.storage_account["app"].blob_properties[0].delete_retention_policy[0].days == 12
    error_message = "app アカウントの Blob 削除保持期間は12日であるべきです"
  }

  # コンテナの削除保持ポリシー
  assert {
    condition     = module.storage.storage_account["app"].blob_properties[0].container_delete_retention_policy[0].days == 7
    error_message = "app アカウントのコンテナ削除保持期間は7日であるべきです"
  }

  # ポイントインタイムリストア
  assert {
    condition     = length(module.storage.storage_account["app"].blob_properties[0].restore_policy) > 0
    error_message = "app アカウントはポイントインタイムリストアを有効にすべきです"
  }

  assert {
    condition     = module.storage.storage_account["app"].blob_properties[0].restore_policy[0].days == 7
    error_message = "app アカウントの復元ポイントは7日であるべきです"
  }

  # 変更フィード
  assert {
    condition     = module.storage.storage_account["app"].blob_properties[0].change_feed_enabled == true
    error_message = "app アカウントは変更フィードを有効にすべきです"
  }

  assert {
    condition     = module.storage.storage_account["app"].blob_properties[0].change_feed_retention_in_days == 12
    error_message = "app アカウントの変更フィード保持期間は12日であるべきです"
  }
}

# ================================================================================
# Test 3: web ストレージアカウントの Static Website 検証
# ================================================================================
# 目的: web アカウントの Static Website 機能とパブリックアクセス設定を確認
run "web_storage_static_website" {
  command = plan

  # web アカウントはパブリックネットワークアクセスが有効
  assert {
    condition     = module.storage.storage_account["web"].public_network_access_enabled == true
    error_message = "web アカウントは Static Website のためパブリックアクセスを有効にすべきです"
  }

  # web アカウントはネットワークルールなし（variables.tf で network_rules = null と設定）
  # 注: network_rules の length は plan 段階で評価できないため、このチェックは省略

  # Static Website の設定
  assert {
    condition     = module.storage.storage_static_website["web"].index_document == "index.html"
    error_message = "web アカウントのインデックスドキュメントは index.html であるべきです"
  }

  assert {
    condition     = module.storage.storage_static_website["web"].error_404_document == "404.html"
    error_message = "web アカウントの404エラードキュメントは 404.html であるべきです"
  }

  # セキュリティ設定は Test 8 (security_best_practices) で全アカウント共通検証
}

# ================================================================================
# Test 4: func ストレージアカウントの検証
# ================================================================================
# 目的: Azure Functions 用ストレージアカウントの設定を確認
run "func_storage_configuration" {
  command = plan

  # func アカウントの基本設定
  assert {
    condition     = module.storage.storage_account["func"].account_tier == "Standard"
    error_message = "func アカウントは Standard tier であるべきです"
  }

  assert {
    condition     = module.storage.storage_account["func"].account_replication_type == "LRS"
    error_message = "func アカウントは LRS レプリケーションであるべきです"
  }

  # パブリックアクセス設定（Azure Functions 要件）
  assert {
    condition     = module.storage.storage_account["func"].public_network_access_enabled == true
    error_message = "func アカウントは Azure Functions のためパブリックネットワークアクセスが有効であるべきです"
  }

  # バージョニング設定（func はパフォーマンス重視で無効）
  assert {
    condition     = module.storage.storage_account["func"].blob_properties[0].versioning_enabled == false
    error_message = "func アカウントはバージョニングを無効にしています（パフォーマンス重視）"
  }
}

# ================================================================================
# Test 5: ストレージ命名規則の検証
# ================================================================================
# 目的: ストレージアカウント名が命名規則に従っていることを確認
run "storage_naming_convention" {
  command = plan

  # ストレージアカウントのキー（識別子）が適切であることを確認
  # 注: 実際の name 属性は plan 段階では "(not yet known)" のため確認できない
  assert {
    condition = alltrue([
      for key in keys(module.storage.storage_account) :
      can(regex("^[a-z]+$", key))
    ])
    error_message = "ストレージアカウントのキーは小文字の英字のみであるべきです"
  }

  # すべてのアカウントで location が japaneast
  assert {
    condition = alltrue([
      for sa in module.storage.storage_account :
      sa.location == "japaneast"
    ])
    error_message = "すべてのストレージアカウントは japaneast リージョンに配置されるべきです"
  }

  # すべてのアカウントで適切なタグが設定されている
  assert {
    condition = alltrue([
      for sa in module.storage.storage_account :
      sa.tags.project == "terraform" && sa.tags.env == "dev"
    ])
    error_message = "すべてのストレージアカウントに適切なタグ（project=terraform, env=dev）が設定されるべきです"
  }
}

# ================================================================================
# Test 6: Blob コンテナの検証
# ================================================================================
# 目的: デフォルトの Blob コンテナ設定を確認
run "blob_container_configuration" {
  command = plan

  # static コンテナの設定
  assert {
    condition     = module.storage.storage_container["app_static"].name == "static"
    error_message = "app_static コンテナの名前は 'static' であるべきです"
  }

  assert {
    condition     = module.storage.storage_container["app_static"].container_access_type == "private"
    error_message = "app_static コンテナはプライベートアクセスであるべきです"
  }

  # media コンテナの設定
  assert {
    condition     = module.storage.storage_container["app_media"].name == "media"
    error_message = "app_media コンテナの名前は 'media' であるべきです"
  }

  assert {
    condition     = module.storage.storage_container["app_media"].container_access_type == "private"
    error_message = "app_media コンテナはプライベートアクセスであるべきです"
  }
}

# ================================================================================
# Test 7: ストレージ管理ポリシーの検証
# ================================================================================
# 目的: デフォルトのライフサイクル管理ポリシーを確認
run "storage_management_policy_configuration" {
  command = plan

  # ライフサイクルポリシーが app と log アカウントに設定されている
  assert {
    condition     = length(module.storage.storage_management_policy) == 2
    error_message = "app と log アカウント用のライフサイクルポリシーが作成されるべきです"
  }

  # ポリシー名
  assert {
    condition     = module.storage.storage_management_policy["app"].rule[0].name == "delete-after-7-days"
    error_message = "ポリシー名は 'delete-after-7-days' であるべきです"
  }

  # Blob タイプ
  assert {
    condition     = contains(module.storage.storage_management_policy["app"].rule[0].filters[0].blob_types, "blockBlob")
    error_message = "Blob タイプに blockBlob が含まれるべきです"
  }

  assert {
    condition     = contains(module.storage.storage_management_policy["app"].rule[0].filters[0].blob_types, "appendBlob")
    error_message = "Blob タイプに appendBlob が含まれるべきです"
  }

  # base_blob のアクション（7日後に削除）
  assert {
    condition     = module.storage.storage_management_policy["app"].rule[0].actions[0].base_blob[0].delete_after_days_since_modification_greater_than == 7
    error_message = "base_blob は変更から7日後に削除されるべきです"
  }

  # snapshot のアクション（7日後に削除）
  assert {
    condition     = module.storage.storage_management_policy["app"].rule[0].actions[0].snapshot[0].delete_after_days_since_creation_greater_than == 7
    error_message = "snapshot は作成から7日後に削除されるべきです"
  }
}

# ================================================================================
# Test 8: セキュリティベストプラクティスの全体検証
# ================================================================================
# 目的: すべてのストレージアカウントがセキュリティベストプラクティスに準拠
run "security_best_practices" {
  command = plan

  # 認証とアクセス制御
  assert {
    condition = alltrue([
      for sa in module.storage.storage_account : sa.shared_access_key_enabled == false
    ])
    error_message = "セキュリティ: すべてのアカウントで共有アクセスキーを無効にすべきです"
  }

  assert {
    condition = alltrue([
      for sa in module.storage.storage_account : sa.default_to_oauth_authentication == true
    ])
    error_message = "セキュリティ: すべてのアカウントで OAuth 認証をデフォルトにすべきです"
  }

  # 通信の暗号化
  assert {
    condition = alltrue([
      for sa in module.storage.storage_account : sa.https_traffic_only_enabled == true
    ])
    error_message = "セキュリティ: すべてのアカウントで HTTPS トラフィックのみ許可すべきです"
  }

  # データ保護
  assert {
    condition = alltrue([
      for key, sa in module.storage.storage_account :
      key == "func" ? true : sa.blob_properties[0].versioning_enabled == true
    ])
    error_message = "データ保護: func 以外のアカウントでバージョニングを有効にすべきです"
  }
}

# ================================================================================
# Test 9: カスタム設定での上書きテスト
# ================================================================================
# 目的: 特定の設定を上書きしてテストできることを確認
run "custom_secure_storage" {
  command = plan

  # variables ブロックで一部の設定のみ上書き
  # 注: func アカウントは他のリソース（key_vault_secret）が依存しているため含める必要がある
  variables {
    storage = {
      secure_test = {
        name                            = "sectest"
        account_tier                    = "Premium"
        account_kind                    = "BlockBlobStorage"
        account_replication_type        = "ZRS"
        access_tier                     = "Hot"
        public_network_access_enabled   = false
        shared_access_key_enabled       = false
        default_to_oauth_authentication = true
        is_hns_enabled                  = false
        defender_for_storage_enabled    = true
        blob_properties = {
          versioning_enabled                = true
          change_feed_enabled               = true
          change_feed_retention_in_days     = 90
          last_access_time_enabled          = true
          delete_retention_policy           = 30
          container_delete_retention_policy = 30
        }
        network_rules = {
          default_action             = "Deny"
          bypass                     = ["AzureServices", "Logging", "Metrics"]
          ip_rules                   = []
          virtual_network_subnet_ids = []
        }
      }
      func = {
        name                            = "func"
        account_tier                    = "Standard"
        account_kind                    = "StorageV2"
        account_replication_type        = "LRS"
        access_tier                     = "Hot"
        public_network_access_enabled   = true
        shared_access_key_enabled       = false
        default_to_oauth_authentication = true
        is_hns_enabled                  = false
        defender_for_storage_enabled    = false
        blob_properties = {
          versioning_enabled                = false
          change_feed_enabled               = false
          change_feed_retention_in_days     = null
          last_access_time_enabled          = false
          delete_retention_policy           = 7
          container_delete_retention_policy = 7
        }
        network_rules = {
          default_action             = "Deny"
          bypass                     = ["AzureServices"]
          ip_rules                   = ["MyIP"]
          virtual_network_subnet_ids = []
        }
      }
    }
    blob_container            = {}
    storage_management_policy = {}
  }

  # Premium tier の設定
  assert {
    condition     = module.storage.storage_account["secure_test"].account_tier == "Premium"
    error_message = "カスタム設定で Premium tier を指定できるべきです"
  }

  assert {
    condition     = module.storage.storage_account["secure_test"].account_kind == "BlockBlobStorage"
    error_message = "Premium tier では BlockBlobStorage を使用できるべきです"
  }

  # Defender for Storage が有効
  assert {
    condition     = length(module.storage.storage_defender) == 1
    error_message = "Defender for Storage を有効にできるべきです"
  }

  # 拡張されたバイパスルール
  assert {
    condition     = contains(module.storage.storage_account["secure_test"].network_rules[0].bypass, "Logging")
    error_message = "ネットワークルールに Logging バイパスを追加できるべきです"
  }

  assert {
    condition     = contains(module.storage.storage_account["secure_test"].network_rules[0].bypass, "Metrics")
    error_message = "ネットワークルールに Metrics バイパスを追加できるべきです"
  }
}

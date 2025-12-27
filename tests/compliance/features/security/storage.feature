# =============================================================================
# Azure Storage Account セキュリティポリシー
# =============================================================================
# このポリシーは、Azure Storage Account のセキュリティベストプラクティスを検証します。
# 参考: https://learn.microsoft.com/azure/storage/common/security-recommendations
# =============================================================================

@storage @security
Feature: Azure Storage Account Security
  Azure Storage Account はセキュリティベストプラクティスに準拠する必要があります

  # ---------------------------------------------------------------------------
  # 通信の暗号化
  # ---------------------------------------------------------------------------
  # なぜ: 転送中のデータを暗号化することで、中間者攻撃を防止します
  @critical
  Scenario: Storage Account は HTTPS トラフィックのみを許可する
    Given I have azurerm_storage_account defined
    Then it must contain https_traffic_only_enabled
    And its value must be true

  # ---------------------------------------------------------------------------
  # 認証とアクセス制御
  # ---------------------------------------------------------------------------
  # なぜ: 共有アクセスキーは漏洩リスクが高く、Azure AD 認証の方が安全です
  @critical
  Scenario: Storage Account は共有アクセスキーを無効にする
    Given I have azurerm_storage_account defined
    Then it must contain shared_access_key_enabled
    And its value must be false

  # なぜ: OAuth 認証を使用することで、RBAC による細かいアクセス制御が可能になります
  @critical
  Scenario: Storage Account は OAuth 認証をデフォルトにする
    Given I have azurerm_storage_account defined
    Then it must contain default_to_oauth_authentication
    And its value must be true

  # ---------------------------------------------------------------------------
  # データ保護
  # ---------------------------------------------------------------------------
  # なぜ: 削除保持ポリシーにより、誤削除したデータを復旧できます
  Scenario: Storage Account は Blob 削除保持ポリシーを設定する
    Given I have azurerm_storage_account defined
    Then it must contain blob_properties
    And it must contain delete_retention_policy

  # なぜ: コンテナレベルの削除保持も重要です
  Scenario: Storage Account はコンテナ削除保持ポリシーを設定する
    Given I have azurerm_storage_account defined
    Then it must contain blob_properties
    And it must contain container_delete_retention_policy

  # ---------------------------------------------------------------------------
  # Blob コンテナのアクセス制御
  # ---------------------------------------------------------------------------
  # なぜ: コンテナをプライベートにすることで、匿名アクセスを防止します
  @critical
  Scenario: Blob コンテナはプライベートアクセスに設定する
    Given I have azurerm_storage_container defined
    Then it must contain container_access_type
    And its value must be "private"

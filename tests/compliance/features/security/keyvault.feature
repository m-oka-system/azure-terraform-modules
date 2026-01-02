# =============================================================================
# Azure Key Vault セキュリティポリシー
# =============================================================================
# このポリシーは、Azure Key Vault のセキュリティベストプラクティスを検証します。
# 参考: https://learn.microsoft.com/azure/key-vault/general/best-practices
# =============================================================================

@keyvault @security
Feature: Azure Key Vault Security
  Azure Key Vault はセキュリティベストプラクティスに準拠する必要があります

  # ---------------------------------------------------------------------------
  # 削除保護
  # ---------------------------------------------------------------------------
  # なぜ: パージ保護を有効にすることで、悪意のある/誤った完全削除を防止します
  # 注: dev 環境では無効にしていることがあるため、存在確認のみ行います
  Scenario: Key Vault はパージ保護設定を持つ
    Given I have azurerm_key_vault defined
    Then it must contain purge_protection_enabled

  # なぜ: ソフトデリートにより、誤削除したシークレットを復旧できます
  @critical
  Scenario: Key Vault はソフトデリート保持期間を設定する
    Given I have azurerm_key_vault defined
    Then it must contain soft_delete_retention_days

  # ---------------------------------------------------------------------------
  # 認証とアクセス制御
  # ---------------------------------------------------------------------------
  # なぜ: RBAC 認証を使用することで、より細かいアクセス制御が可能になります
  # Access Policy よりも RBAC の方が推奨されています
  @critical
  Scenario: Key Vault は RBAC 認証を使用する
    Given I have azurerm_key_vault defined
    Then it must contain rbac_authorization_enabled
    And its value must be true

  # ---------------------------------------------------------------------------
  # ネットワークセキュリティ
  # ---------------------------------------------------------------------------
  # なぜ: ネットワーク ACL を設定することで、アクセス元を制限できます
  @critical
  Scenario: Key Vault はネットワーク ACL を設定する
    Given I have azurerm_key_vault defined
    Then it must contain network_acls

  # なぜ: デフォルトアクションを Deny にすることで、明示的に許可されたアクセスのみを許可します
  Scenario: Key Vault のネットワーク ACL はデフォルトで Deny
    Given I have azurerm_key_vault defined
    Then it must contain network_acls
    And it must contain default_action
    And its value must be "Deny"

  # なぜ: Azure サービスからのアクセスは許可する必要があることが多いです
  Scenario: Key Vault は Azure サービスからのアクセスを許可する
    Given I have azurerm_key_vault defined
    Then it must contain network_acls
    And it must contain bypass
    And its value must contain "AzureServices"

  # ---------------------------------------------------------------------------
  # SKU
  # ---------------------------------------------------------------------------
  # なぜ: Standard または Premium SKU を使用することで、必要な機能を利用できます
  Scenario: Key Vault は適切な SKU を使用する
    Given I have azurerm_key_vault defined
    Then it must contain sku_name
    And its value must match the "standard|premium" regex

# =============================================================================
# Azure Container Services セキュリティポリシー
# =============================================================================
# このポリシーは、Azure Container Registry および Container Apps の
# セキュリティベストプラクティスを検証します。
# 参考:
#   - https://learn.microsoft.com/azure/container-registry/container-registry-best-practices
#   - https://learn.microsoft.com/azure/container-apps/security
# =============================================================================

@container @security
Feature: Azure Container Services Security
  Azure コンテナサービスはセキュリティベストプラクティスに準拠する必要があります

  # ===========================================================================
  # Azure Container Registry
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # 認証
  # ---------------------------------------------------------------------------
  # なぜ: Admin アカウントは共有される認証情報であり、セキュリティリスクがあります
  # Azure AD 認証（RBAC）を使用することが推奨されています
  @critical
  Scenario: Container Registry は Admin アカウントを無効にする
    Given I have azurerm_container_registry defined
    Then it must contain admin_enabled
    And its value must be false

  # ---------------------------------------------------------------------------
  # ネットワークセキュリティ
  # ---------------------------------------------------------------------------
  # なぜ: パブリックネットワークアクセスを無効にすることで、
  # プライベートエンドポイント経由のアクセスのみに制限できます
  # 注: Premium SKU でのみ完全なネットワーク分離が可能
  Scenario: Container Registry はパブリックネットワークアクセスを制限する
    Given I have azurerm_container_registry defined
    Then it must contain public_network_access_enabled

  # ---------------------------------------------------------------------------
  # SKU
  # ---------------------------------------------------------------------------
  # なぜ: Premium SKU を使用することで、ゾーン冗長やプライベートエンドポイントなど
  # 高度なセキュリティ機能を利用できます
  Scenario: Container Registry は適切な SKU を使用する
    Given I have azurerm_container_registry defined
    Then it must contain sku
    And its value must match the "Basic|Standard|Premium" regex

  # ===========================================================================
  # Azure Container Apps
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # 環境設定
  # ---------------------------------------------------------------------------
  # なぜ: Container App Environment を使用することで、
  # ネットワーク分離やログ管理が可能になります
  Scenario: Container App は Environment を使用する
    Given I have azurerm_container_app defined
    Then it must contain container_app_environment_id

  # ---------------------------------------------------------------------------
  # リソース制限
  # ---------------------------------------------------------------------------
  # なぜ: CPU とメモリの制限を設定することで、リソースの過剰消費を防止できます
  Scenario: Container App はリソース制限を設定する
    Given I have azurerm_container_app defined
    Then it must contain template
    And it must contain container

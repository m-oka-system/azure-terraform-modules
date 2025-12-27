# =============================================================================
# Azure タグポリシー
# =============================================================================
# このポリシーは、Azure リソースのタグ付け要件を検証します。
# タグは、コスト管理、運用、セキュリティ、ガバナンスのために重要です。
# 参考: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-tagging
# =============================================================================

@tagging @governance
Feature: Azure Resource Tagging
  すべての Azure リソースは適切なタグを持つ必要があります

  # ---------------------------------------------------------------------------
  # リソースグループ（タグポリシーの基本）
  # ---------------------------------------------------------------------------
  # なぜ: リソースグループにタグを付けることで、グループ内のリソースに
  # 一貫したタグを継承させることができます
  @critical
  Scenario: リソースグループは project タグを持つ
    Given I have azurerm_resource_group defined
    Then it must contain tags
    And it must contain "project"

  Scenario: リソースグループは env タグを持つ
    Given I have azurerm_resource_group defined
    Then it must contain tags
    And it must contain "env"

  # ---------------------------------------------------------------------------
  # 主要なリソース（個別チェック）
  # ---------------------------------------------------------------------------
  # なぜ: 主要なリソースには個別にタグを確認します
  # Key Vault Secret/Certificate はタグをサポートしないため除外

  Scenario: Storage Account は project タグを持つ
    Given I have azurerm_storage_account defined
    Then it must contain tags
    And it must contain "project"

  Scenario: Storage Account は env タグを持つ
    Given I have azurerm_storage_account defined
    Then it must contain tags
    And it must contain "env"

  Scenario: Key Vault は project タグを持つ
    Given I have azurerm_key_vault defined
    Then it must contain tags
    And it must contain "project"

  Scenario: Key Vault は env タグを持つ
    Given I have azurerm_key_vault defined
    Then it must contain tags
    And it must contain "env"

  Scenario: Virtual Network は project タグを持つ
    Given I have azurerm_virtual_network defined
    Then it must contain tags
    And it must contain "project"

  Scenario: Virtual Network は env タグを持つ
    Given I have azurerm_virtual_network defined
    Then it must contain tags
    And it must contain "env"

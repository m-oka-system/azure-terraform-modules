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
  # すべてのタグ対応リソース（一括チェック）
  # ---------------------------------------------------------------------------
  # なぜ: タグは、コスト管理、運用、セキュリティ、ガバナンスのために重要です
  # "resource that supports tags" はタグをサポートするすべてのリソースを対象にします
  #
  # 注: Key Vault Secret/Certificate は terraform-compliance では「タグ対応」と
  # 認識されますが、Azure API では実際にはタグをサポートしていないため除外します
  @critical
  Scenario Outline: すべてのリソースは <tag> タグを持つ
    Given I have resource that supports tags defined
    When its type is not azurerm_key_vault_secret
    When its type is not azurerm_key_vault_certificate
    Then it must contain tags
    And it must contain "<tag>"

    Examples:
      | tag     |
      | project |
      | env     |

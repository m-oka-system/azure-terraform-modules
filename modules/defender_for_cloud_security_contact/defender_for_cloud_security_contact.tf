##########################################
# Defender for Cloud の電子メール通知設定
##########################################
# リファレンス: https://learn.microsoft.com/ja-jp/azure/templates/microsoft.security/securitycontacts
resource "azapi_resource" "security_contact" {
  type      = "Microsoft.Security/securityContacts@2023-12-01-preview"
  name      = "default"
  parent_id = "/subscriptions/${var.subscription_id}"

  body = {
    properties = {
      emails    = length(var.security_contact.emails) > 0 ? join(";", var.security_contact.emails) : ""
      isEnabled = var.security_contact.is_enabled
      notificationsByRole = {
        state = var.security_contact.notifications_by_role.state
        roles = var.security_contact.notifications_by_role.roles
      }
      notificationsSources = concat(
        # 重要度レベルのアラート通知（常に含める）
        [
          {
            sourceType      = "Alert"
            minimalSeverity = var.security_contact.alert_notifications.minimal_severity
          }
        ],
        # リスクレベルの攻撃パス通知（有効な場合のみ含める）
        var.security_contact.attack_path_notifications.enabled ? [
          {
            sourceType       = "AttackPath"
            minimalRiskLevel = var.security_contact.attack_path_notifications.minimal_risk_level
          }
        ] : []
      )
      phone = var.security_contact.phone != null ? var.security_contact.phone : ""
    }
  }
}

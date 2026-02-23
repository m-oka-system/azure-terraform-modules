##########################################
# Microsoft Defender for Cloud
##########################################
resource "azurerm_security_center_subscription_pricing" "this" {
  for_each      = var.security_center_subscription_pricing
  tier          = each.value.tier
  resource_type = each.value.resource_type
}

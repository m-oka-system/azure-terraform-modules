################################
# Azure AI Search
################################
resource "azurerm_search_service" "this" {
  for_each                      = var.aisearch
  name                          = "search-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name           = var.resource_group_name
  location                      = var.common.location
  sku                           = each.value.sku
  semantic_search_sku           = each.value.semantic_search_sku
  partition_count               = each.value.partition_count
  replica_count                 = each.value.replica_count
  public_network_access_enabled = each.value.public_network_access_enabled
  network_rule_bypass_option    = each.value.network_rule_bypass_option
  allowed_ips                   = join(",", lookup(each.value, "allowed_ips", null)) == "MyIP" ? var.allowed_cidr : lookup(each.value, "allowed_ips", null)

  tags = var.tags
}

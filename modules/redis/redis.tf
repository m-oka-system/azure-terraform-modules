################################
# Azure Cache for Redis
################################
resource "azurerm_redis_cache" "this" {
  for_each                      = var.redis_cache
  name                          = "redis-${each.value.name}-${var.common.project}-${var.common.env}-${var.random}"
  resource_group_name           = var.resource_group_name
  location                      = var.common.location
  capacity                      = each.value.capacity
  family                        = each.value.family
  sku_name                      = each.value.sku_name
  redis_version                 = each.value.redis_version
  public_network_access_enabled = each.value.public_network_access_enabled
  non_ssl_port_enabled          = each.value.non_ssl_port_enabled
  minimum_tls_version           = each.value.minimum_tls_version

  tags = var.tags
}

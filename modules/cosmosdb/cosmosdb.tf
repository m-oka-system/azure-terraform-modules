##########################################
# Azure Cosmos DB
##########################################
resource "azurerm_cosmosdb_account" "this" {
  for_each                      = var.cosmosdb_account
  name                          = "cosmos-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name           = var.resource_group_name
  location                      = var.common.location
  offer_type                    = each.value.offer_type
  kind                          = each.value.kind
  free_tier_enabled             = each.value.free_tier_enabled
  public_network_access_enabled = each.value.public_network_access_enabled
  ip_range_filter               = join(",", lookup(each.value, "ip_range_filter", null)) == "MyIP" ? var.allowed_cidr : lookup(each.value, "ip_range_filter", null)

  consistency_policy {
    consistency_level       = each.value.consistency_policy.consistency_level
    max_interval_in_seconds = each.value.consistency_policy.max_interval_in_seconds
    max_staleness_prefix    = each.value.consistency_policy.max_staleness_prefix
  }

  geo_location {
    location          = each.value.geo_location.location
    failover_priority = each.value.geo_location.failover_priority
    zone_redundant    = each.value.geo_location.zone_redundant
  }

  capacity {
    total_throughput_limit = each.value.capacity.total_throughput_limit
  }

  backup {
    type = each.value.backup.type
    tier = each.value.backup.tier
  }

  tags = var.tags
}

resource "azurerm_cosmosdb_sql_database" "this" {
  for_each            = var.cosmosdb_sql_database
  name                = each.value.name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this[each.value.target_cosmosdb_account].name

  dynamic "autoscale_settings" {
    for_each = each.value.autoscale_settings != null ? [true] : []

    content {
      max_throughput = each.value.autoscale_settings.max_throughput
    }
  }
}

resource "azurerm_cosmosdb_sql_container" "this" {
  for_each              = var.cosmosdb_sql_container
  name                  = each.value.name
  resource_group_name   = var.resource_group_name
  account_name          = azurerm_cosmosdb_account.this[each.value.target_cosmosdb_account].name
  database_name         = azurerm_cosmosdb_sql_database.this[each.value.target_cosmosdb_sql_database].name
  partition_key_paths   = each.value.partition_key_paths
  partition_key_version = each.value.partition_key_version

  dynamic "autoscale_settings" {
    for_each = each.value.autoscale_settings != null ? [true] : []

    content {
      max_throughput = each.value.autoscale_settings.max_throughput
    }
  }
}

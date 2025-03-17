################################
# Storage Account
################################
resource "azurerm_storage_account" "this" {
  for_each                      = var.storage
  name                          = replace("st-${var.common.project}-${var.common.env}-${each.value.name}-${var.random}", "-", "")
  resource_group_name           = var.resource_group_name
  location                      = var.common.location
  account_tier                  = each.value.account_tier
  account_kind                  = each.value.account_kind
  account_replication_type      = each.value.account_replication_type
  access_tier                   = each.value.access_tier
  https_traffic_only_enabled    = each.value.https_traffic_only_enabled
  public_network_access_enabled = each.value.public_network_access_enabled
  is_hns_enabled                = each.value.is_hns_enabled

  blob_properties {
    versioning_enabled       = each.value.blob_properties.versioning_enabled
    change_feed_enabled      = each.value.blob_properties.change_feed_enabled
    last_access_time_enabled = each.value.blob_properties.last_access_time_enabled

    delete_retention_policy {
      days = each.value.blob_properties.delete_retention_policy
    }

    container_delete_retention_policy {
      days = each.value.blob_properties.container_delete_retention_policy
    }
  }

  dynamic "network_rules" {
    for_each = each.value.network_rules != null ? [true] : []

    content {
      default_action             = each.value.network_rules.default_action
      bypass                     = each.value.network_rules.bypass
      ip_rules                   = join(",", lookup(each.value.network_rules, "ip_rules", null)) == "MyIP" ? split(",", var.allowed_cidr) : lookup(each.value.network_rules, "ip_rules", null)
      virtual_network_subnet_ids = each.value.network_rules.virtual_network_subnet_ids
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "this" {
  for_each              = var.blob_container
  name                  = each.value.container_name
  storage_account_id    = azurerm_storage_account.this[each.value.target_storage_account].id
  container_access_type = each.value.container_access_type
}

resource "azurerm_storage_management_policy" "this" {
  for_each           = var.storage_management_policy
  storage_account_id = azurerm_storage_account.this[each.key].id

  rule {
    name    = each.value.name
    enabled = true

    filters {
      blob_types = each.value.blob_types
    }

    actions {
      dynamic "base_blob" {
        for_each = lookup(each.value.actions, "base_blob", null) != null ? { base_blob = each.value.actions.base_blob } : {}

        content {
          auto_tier_to_hot_from_cool_enabled                             = lookup(base_blob.value, "auto_tier_to_hot_from_cool_enabled", false)
          delete_after_days_since_creation_greater_than                  = lookup(base_blob.value, "delete_after_days_since_creation_greater_than", -1)
          delete_after_days_since_last_access_time_greater_than          = lookup(base_blob.value, "delete_after_days_since_last_access_time_greater_than", -1)
          delete_after_days_since_modification_greater_than              = lookup(base_blob.value, "delete_after_days_since_modification_greater_than", -1)
          tier_to_archive_after_days_since_creation_greater_than         = lookup(base_blob.value, "tier_to_archive_after_days_since_creation_greater_than", -1)
          tier_to_archive_after_days_since_last_access_time_greater_than = lookup(base_blob.value, "tier_to_archive_after_days_since_last_access_time_greater_than", -1)
          tier_to_archive_after_days_since_last_tier_change_greater_than = lookup(base_blob.value, "tier_to_archive_after_days_since_last_tier_change_greater_than", -1)
          tier_to_archive_after_days_since_modification_greater_than     = lookup(base_blob.value, "tier_to_archive_after_days_since_modification_greater_than", -1)
          tier_to_cold_after_days_since_creation_greater_than            = lookup(base_blob.value, "tier_to_cold_after_days_since_creation_greater_than", -1)
          tier_to_cold_after_days_since_last_access_time_greater_than    = lookup(base_blob.value, "tier_to_cold_after_days_since_last_access_time_greater_than", -1)
          tier_to_cold_after_days_since_modification_greater_than        = lookup(base_blob.value, "tier_to_cold_after_days_since_modification_greater_than", -1)
          tier_to_cool_after_days_since_creation_greater_than            = lookup(base_blob.value, "tier_to_cool_after_days_since_creation_greater_than", -1)
          tier_to_cool_after_days_since_last_access_time_greater_than    = lookup(base_blob.value, "tier_to_cool_after_days_since_last_access_time_greater_than", -1)
          tier_to_cool_after_days_since_modification_greater_than        = lookup(base_blob.value, "tier_to_cool_after_days_since_modification_greater_than", -1)
        }
      }

      dynamic "snapshot" {
        for_each = lookup(each.value.actions, "snapshot", null) != null ? { snapshot = each.value.actions.snapshot } : {}

        content {
          change_tier_to_archive_after_days_since_creation               = lookup(snapshot.value, "change_tier_to_archive_after_days_since_creation", -1)
          change_tier_to_cool_after_days_since_creation                  = lookup(snapshot.value, "change_tier_to_cool_after_days_since_creation", -1)
          delete_after_days_since_creation_greater_than                  = lookup(snapshot.value, "delete_after_days_since_creation_greater_than", -1)
          tier_to_archive_after_days_since_last_tier_change_greater_than = lookup(snapshot.value, "tier_to_archive_after_days_since_last_tier_change_greater_than", -1)
          tier_to_cold_after_days_since_creation_greater_than            = lookup(snapshot.value, "tier_to_cold_after_days_since_creation_greater_than", -1)
        }
      }

      dynamic "version" {
        for_each = lookup(each.value.actions, "version", null) != null ? { version = each.value.actions.version } : {}

        content {
          change_tier_to_archive_after_days_since_creation               = lookup(version.value, "change_tier_to_archive_after_days_since_creation", -1)
          change_tier_to_cool_after_days_since_creation                  = lookup(version.value, "change_tier_to_cool_after_days_since_creation", -1)
          delete_after_days_since_creation                               = lookup(version.value, "delete_after_days_since_creation", -1)
          tier_to_archive_after_days_since_last_tier_change_greater_than = lookup(version.value, "tier_to_archive_after_days_since_last_tier_change_greater_than", -1)
          tier_to_cold_after_days_since_creation_greater_than            = lookup(version.value, "tier_to_cold_after_days_since_creation_greater_than", -1)
        }
      }
    }
  }
}

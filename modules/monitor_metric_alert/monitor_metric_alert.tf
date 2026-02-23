################################
# Metric Alert
################################
locals {
  metric_alerts = flatten([
    for namespace, config in var.metric_alert : [
      for resource_key, resource in config.resources : [
        for metric_name, metric in config.metrics : {
          key              = "${namespace}_${metric_name}_${resource_key}"
          metric_namespace = namespace
          metric_name      = metric_name
          resource_name    = resource.name
          scope_id         = resource.id
          metric           = metric
        }
      ]
    ]
  ])
}

resource "azurerm_monitor_metric_alert" "this" {
  for_each            = { for alert in local.metric_alerts : alert.key => alert }
  name                = "${each.value.resource_name}_${each.value.metric.display_name}"
  resource_group_name = var.resource_group_name
  scopes              = [each.value.scope_id]
  enabled             = each.value.metric.enabled
  severity            = each.value.metric.severity
  frequency           = each.value.metric.frequency
  window_size         = each.value.metric.window_size

  criteria {
    metric_namespace = each.value.metric_namespace
    metric_name      = each.value.metric_name
    aggregation      = each.value.metric.aggregation
    operator         = each.value.metric.operator
    threshold        = each.value.metric.threshold
  }

  action {
    action_group_id = var.action_group[each.value.metric.target_action_group].id
  }

  tags = var.tags
}

# 入力データ（locals.tf）
#   metric_alert = {
#     "Microsoft.Storage/storageAccounts" = {
#       resources = {
#         app  = { id = "/subscriptions/.../stappdev",  name = "stappdev" }
#         logs = { id = "/subscriptions/.../stlogsdev", name = "stlogsdev" }
#       }
#       metrics = {
#         Availability = { display_name = "Availability", enabled = false, ... }
#         UsedCapacity = { display_name = "Used_Capacity", enabled = false, ... }
#       }
#     }
#     ...
#   }

#   flatten の展開プロセス
#   1st loop: for namespace, config in var.metric_alert
#   ├─ namespace = "Microsoft.Storage/storageAccounts"
#   │  config = { resources = { app, logs }, metrics = { Availability, UsedCapacity } }
#   │
#   │  2nd loop: for resource_key, resource in config.resources
#   │  ├─ resource_key = "app", resource = { id, name = "stappdev" } # module 出力を展開
#   │  │
#   │  │  3rd loop: for metric_name, metric in config.metrics
#   │  │  ├─ metric_name = "Availability" → { key = "..._Availability_app", ... }
#   │  │  └─ metric_name = "UsedCapacity" → { key = "..._UsedCapacity_app", ... }
#   │  │
#   │  └─ resource_key = "logs", resource = { id, name = "stlogsdev" }
#   │     │
#   │     3rd loop: for metric_name, metric in config.metrics
#   │     ├─ metric_name = "Availability" → { key = "..._Availability_logs", ... }
#   │     └─ metric_name = "UsedCapacity" → { key = "..._UsedCapacity_logs", ... }
#   │
#   └─ namespace = "Microsoft.KeyVault/vaults"
#      config = { resources = { app }, metrics = { Availability, ServiceApiLatency } }
#      ...

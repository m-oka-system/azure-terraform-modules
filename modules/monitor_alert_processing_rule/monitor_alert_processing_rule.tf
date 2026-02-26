################################
# Alert Processing Rule
################################
resource "azurerm_monitor_alert_processing_rule_action_group" "this" {
  for_each = var.alert_processing_rule

  name                 = "apr-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name  = var.resource_group_name
  scopes               = each.value.scopes
  add_action_group_ids = [var.action_group[each.value.target_action_group].id]
  description          = lookup(each.value, "description", null)
  enabled              = lookup(each.value, "enabled", null)

  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [true] : []

    content {
      dynamic "severity" {
        for_each = lookup(each.value.condition, "severity", null) != null ? [each.value.condition.severity] : []

        content {
          operator = severity.value.operator
          values   = severity.value.values
        }
      }

      dynamic "monitor_service" {
        for_each = lookup(each.value.condition, "monitor_service", null) != null ? [each.value.condition.monitor_service] : []

        content {
          operator = monitor_service.value.operator
          values   = monitor_service.value.values
        }
      }

      dynamic "monitor_condition" {
        for_each = lookup(each.value.condition, "monitor_condition", null) != null ? [each.value.condition.monitor_condition] : []

        content {
          operator = monitor_condition.value.operator
          values   = monitor_condition.value.values
        }
      }

      dynamic "signal_type" {
        for_each = lookup(each.value.condition, "signal_type", null) != null ? [each.value.condition.signal_type] : []

        content {
          operator = signal_type.value.operator
          values   = signal_type.value.values
        }
      }

      dynamic "target_resource_type" {
        for_each = lookup(each.value.condition, "target_resource_type", null) != null ? [each.value.condition.target_resource_type] : []

        content {
          operator = target_resource_type.value.operator
          values   = target_resource_type.value.values
        }
      }

      dynamic "alert_context" {
        for_each = lookup(each.value.condition, "alert_context", null) != null ? [each.value.condition.alert_context] : []

        content {
          operator = alert_context.value.operator
          values   = alert_context.value.values
        }
      }

      dynamic "alert_rule_name" {
        for_each = lookup(each.value.condition, "alert_rule_name", null) != null ? [each.value.condition.alert_rule_name] : []

        content {
          operator = alert_rule_name.value.operator
          values   = alert_rule_name.value.values
        }
      }

      dynamic "target_resource" {
        for_each = lookup(each.value.condition, "target_resource", null) != null ? [each.value.condition.target_resource] : []

        content {
          operator = target_resource.value.operator
          values   = target_resource.value.values
        }
      }

      dynamic "target_resource_group" {
        for_each = lookup(each.value.condition, "target_resource_group", null) != null ? [each.value.condition.target_resource_group] : []

        content {
          operator = target_resource_group.value.operator
          values   = target_resource_group.value.values
        }
      }
    }
  }

  dynamic "schedule" {
    for_each = lookup(each.value, "schedule", null) != null ? [each.value.schedule] : []

    content {
      effective_from  = lookup(schedule.value, "effective_from", null)
      effective_until = lookup(schedule.value, "effective_until", null)
      time_zone       = lookup(schedule.value, "time_zone", null)

      dynamic "recurrence" {
        for_each = lookup(schedule.value, "recurrence", null) != null ? [schedule.value.recurrence] : []

        content {
          dynamic "daily" {
            for_each = lookup(recurrence.value, "daily", null) != null ? recurrence.value.daily : []

            content {
              start_time = daily.value.start_time
              end_time   = daily.value.end_time
            }
          }

          dynamic "weekly" {
            for_each = lookup(recurrence.value, "weekly", null) != null ? recurrence.value.weekly : []

            content {
              days_of_week = weekly.value.days_of_week
              start_time   = lookup(weekly.value, "start_time", null)
              end_time     = lookup(weekly.value, "end_time", null)
            }
          }

          dynamic "monthly" {
            for_each = lookup(recurrence.value, "monthly", null) != null ? recurrence.value.monthly : []

            content {
              days_of_month = monthly.value.days_of_month
              start_time    = lookup(monthly.value, "start_time", null)
              end_time      = lookup(monthly.value, "end_time", null)
            }
          }
        }
      }
    }
  }

  tags = var.tags
}

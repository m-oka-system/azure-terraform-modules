################################
# Log Query Alert
################################
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "this" {
  for_each             = var.log_query_alert
  name                 = each.key
  resource_group_name  = var.resource_group_name
  location             = var.common.location
  enabled              = each.value.enabled
  severity             = each.value.severity
  evaluation_frequency = each.value.evaluation_frequency
  window_duration      = each.value.window_duration

  scopes = [
    each.value.scope_id
  ]

  criteria {
    query                   = each.value.criteria.query
    time_aggregation_method = each.value.criteria.time_aggregation_method
    metric_measure_column   = each.value.criteria.metric_measure_column
    operator                = each.value.criteria.operator
    threshold               = each.value.criteria.threshold
  }

  auto_mitigation_enabled          = each.value.auto_mitigation_enabled
  workspace_alerts_storage_enabled = each.value.workspace_alerts_storage_enabled
  skip_query_validation            = each.value.skip_query_validation

  action {
    action_groups = [
      var.action_group[each.value.target_action_group].id
    ]
  }

  tags = var.tags
}

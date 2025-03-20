################################
# Metric Alert
################################
resource "azurerm_monitor_metric_alert" "this" {
  for_each            = { for item in local.metric_resources : item.key => item }
  name                = "${each.value.metric_name}_${each.value.name}"
  resource_group_name = var.resource_group_name
  scopes              = [each.value.scope_id]
  enabled             = each.value.enabled
  severity            = each.value.severity
  frequency           = each.value.frequency
  window_size         = each.value.window_size

  criteria {
    metric_namespace = each.value.metric_namespace
    metric_name      = each.value.metric_name
    aggregation      = each.value.aggregation
    operator         = each.value.operator
    threshold        = each.value.threshold
  }

  action {
    action_group_id = var.action_group[each.value.target_action_group].id
  }

  tags = var.tags
}

locals {
  # リソースとメトリックの組み合わせをフラット化
  metric_resources = flatten([
    for namespace, namespace_config in var.metric_alert : [
      for metric in namespace_config.metrics : [
        for resource_key, resource in namespace_config.resources : {
          key              = "${namespace}_${metric.metric_name}_${resource_key}"
          metric_namespace = namespace
          resource_key     = resource_key
          scope_id         = resource.id
          name             = resource.name

          # メトリックアラートの設定
          enabled             = metric.enabled
          metric_name         = metric.metric_name
          aggregation         = metric.aggregation
          operator            = metric.operator
          threshold           = metric.threshold
          frequency           = metric.frequency
          window_size         = metric.window_size
          severity            = metric.severity
          target_action_group = metric.target_action_group
        }
      ]
    ]
  ])
}

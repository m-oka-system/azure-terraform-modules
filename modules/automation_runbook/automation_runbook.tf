################################
# Automation Runbook
################################
locals {
  schedules = { for k, v in var.automation_runbook : k => v.schedule if v.schedule != null }
}

resource "time_static" "this" {}

# Automation 変数
resource "azurerm_automation_variable_string" "this" {
  for_each                = var.automation_variable
  name                    = each.value.name
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  value                   = each.value.value
  encrypted               = false
}

# Runbook
resource "azurerm_automation_runbook" "this" {
  for_each                = var.automation_runbook
  name                    = each.key
  location                = var.common.location
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell72"
  content                 = file("${path.module}/runbook/${each.key}.ps1")

  tags = var.tags
}

# スケジュール
resource "azurerm_automation_schedule" "this" {
  for_each                = local.schedules
  name                    = "${each.key}-Schedule"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  frequency               = each.value.frequency
  interval                = each.value.interval
  timezone                = "Asia/Tokyo"
  start_time              = "${formatdate("YYYY-MM-DD", timeadd(time_static.this.rfc3339, "24h"))}T${each.value.start_time}:00+09:00"
  description             = each.value.description
  week_days               = each.value.week_days
}

# Runbook とスケジュールの関連付け
resource "azurerm_automation_job_schedule" "this" {
  for_each                = local.schedules
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  runbook_name            = azurerm_automation_runbook.this[each.key].name
  schedule_name           = azurerm_automation_schedule.this[each.key].name
}

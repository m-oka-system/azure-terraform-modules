################################
# App Service Plan
################################
resource "azurerm_service_plan" "this" {
  for_each            = var.app_service_plan
  name                = "asp-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name = var.resource_group_name
  location            = var.common.location
  os_type             = each.value.os_type
  sku_name            = each.value.sku_name

  tags = var.tags
}

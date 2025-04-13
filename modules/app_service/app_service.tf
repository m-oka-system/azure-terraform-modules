################################
# Web App for Containers
################################
resource "azurerm_linux_web_app" "this" {
  for_each                                       = var.app_service
  name                                           = "webapp-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name                            = var.resource_group_name
  location                                       = var.common.location
  service_plan_id                                = var.app_service_plan[each.value.target_service_plan].id
  virtual_network_subnet_id                      = var.subnet[each.value.target_subnet].id
  ftp_publish_basic_authentication_enabled       = each.value.ftp_publish_basic_authentication_enabled
  webdeploy_publish_basic_authentication_enabled = each.value.webdeploy_publish_basic_authentication_enabled
  https_only                                     = each.value.https_only
  public_network_access_enabled                  = each.value.public_network_access_enabled
  key_vault_reference_identity_id                = var.identity[each.value.target_user_assigned_identity].id

  identity {
    type = "UserAssigned"
    identity_ids = [
      var.identity[each.value.target_user_assigned_identity].id
    ]
  }

  app_settings = var.app_settings[each.key]

  site_config {
    always_on                                     = each.value.site_config.always_on
    ftps_state                                    = each.value.site_config.ftps_state
    vnet_route_all_enabled                        = each.value.site_config.vnet_route_all_enabled
    scm_use_main_ip_restriction                   = false
    container_registry_use_managed_identity       = true
    container_registry_managed_identity_client_id = var.identity[each.value.target_user_assigned_identity].client_id


    dynamic "cors" {
      for_each = each.value.site_config.cors != null ? [true] : []

      content {
        allowed_origins     = var.allowed_origins[each.key]
        support_credentials = each.value.site_config.cors.support_credentials
      }
    }

    dynamic "ip_restriction" {
      for_each = each.value.ip_restriction

      content {
        name        = ip_restriction.value.name
        priority    = ip_restriction.value.priority
        action      = ip_restriction.value.action
        ip_address  = lookup(ip_restriction.value, "ip_address", null) == "MyIP" ? join(",", [for ip in var.allowed_cidr : "${ip}/32"]) : lookup(ip_restriction.value, "ip_address", null)
        service_tag = ip_restriction.value.service_tag

        dynamic "headers" {
          for_each = ip_restriction.key == "frontdoor" ? [true] : []

          content {
            x_azure_fdid = [
              var.frontdoor_profile.resource_guid
            ]
            x_fd_health_probe = []
            x_forwarded_for   = []
            x_forwarded_host  = []
          }
        }
      }
    }

    dynamic "scm_ip_restriction" {
      for_each = each.value.scm_ip_restriction

      content {
        name        = scm_ip_restriction.value.name
        priority    = scm_ip_restriction.value.priority
        action      = scm_ip_restriction.value.action
        ip_address  = lookup(scm_ip_restriction.value, "ip_address", null) == "MyIP" ? join(",", [for ip in var.allowed_cidr : "${ip}/32"]) : lookup(scm_ip_restriction.value, "ip_address", null)
        service_tag = scm_ip_restriction.value.service_tag
      }
    }

    application_stack {
      # Initial container image (overwritten by CI/CD)
      docker_image_name   = "appsvc/staticsite:latest"
      docker_registry_url = "https://mcr.microsoft.com"
    }
  }

  lifecycle {
    ignore_changes = [
      site_config[0].application_stack[0].docker_image_name,
      site_config[0].application_stack[0].docker_registry_url,
      tags["hidden-link: /app-insights-conn-string"],
      tags["hidden-link: /app-insights-instrumentation-key"],
      tags["hidden-link: /app-insights-resource-id"],
    ]
  }

  tags = var.tags
}

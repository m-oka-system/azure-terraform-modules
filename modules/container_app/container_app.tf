################################
# Container App
################################
resource "azurerm_container_app" "this" {
  for_each                     = var.container_app
  name                         = "ca-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment[each.value.target_container_app_environment].id
  workload_profile_name        = each.value.workload_profile_name
  revision_mode                = each.value.revision_mode

  identity {
    type = "UserAssigned"
    identity_ids = [
      var.identity[each.value.target_user_assigned_identity].id
    ]
  }

  template {
    min_replicas = each.value.template.min_replicas
    max_replicas = each.value.template.max_replicas

    container {
      name = each.value.template.container.name
      # Initial container image (overwritten by CI/CD)
      image  = "mcr.microsoft.com/k8se/quickstart:latest"
      cpu    = each.value.template.container.cpu
      memory = each.value.template.container.memory
    }

    http_scale_rule {
      name                = each.value.template.http_scale_rule.name
      concurrent_requests = each.value.template.http_scale_rule.concurrent_requests
    }
  }

  ingress {
    external_enabled           = each.value.ingress.external_enabled
    allow_insecure_connections = each.value.ingress.allow_insecure_connections
    client_certificate_mode    = each.value.ingress.client_certificate_mode
    transport                  = each.value.ingress.transport
    target_port                = each.value.ingress.target_port

    dynamic "ip_security_restriction" {
      for_each = toset(var.allowed_cidr)
      content {
        name             = each.value.ingress.ip_security_restriction.name
        action           = each.value.ingress.ip_security_restriction.action
        ip_address_range = ip_security_restriction.value
      }
    }

    traffic_weight {
      latest_revision = each.value.ingress.traffic_weight.latest_revision
      percentage      = each.value.ingress.traffic_weight.percentage
    }
  }

  registry {
    server   = var.container_registry[each.value.target_container_registry].login_server
    identity = var.identity[each.value.target_user_assigned_identity].id
  }

  lifecycle {
    ignore_changes = [
      template[0].container[0].image,
    ]
  }

  tags = var.tags
}

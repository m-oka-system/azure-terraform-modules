################################
# Application Gateway
################################
locals {
  application_gateway_public_ip_name = "ip-appgw-${var.common.project}-${var.common.env}"
  application_gateway_name           = "appgw-${var.common.project}-${var.common.env}"
  frontend_ip_configuration_name     = "appgw-feip-${var.common.project}-${var.common.env}"
  backend_address_pool_name          = "appgw-bepool-${var.common.project}-${var.common.env}"
  backend_http_settings_name         = "appgw-http-setting-${var.common.project}-${var.common.env}"
  http_listener_name                 = "appgw-http-listener-${var.common.project}-${var.common.env}"
  https_listener_name                = "appgw-https-listener-${var.common.project}-${var.common.env}"
  http_request_routing_rule_name     = "appgw-http-rule-${var.common.project}-${var.common.env}"
  https_request_routing_rule_name    = "appgw-https-rule-${var.common.project}-${var.common.env}"
  probe_name                         = "appgw-probe-${var.common.project}-${var.common.env}"
}

resource "azurerm_public_ip" "this" {
  name                = local.application_gateway_public_ip_name
  resource_group_name = var.resource_group_name
  location            = var.common.location
  sku                 = var.application_gateway.public_ip.sku
  allocation_method   = var.application_gateway.public_ip.allocation_method
  zones               = var.application_gateway.public_ip.zones

  tags = var.tags
}

resource "azurerm_application_gateway" "this" {
  name                              = local.application_gateway_name
  resource_group_name               = var.resource_group_name
  location                          = var.common.location
  enable_http2                      = var.application_gateway.enable_http2
  fips_enabled                      = var.application_gateway.fips_enabled
  force_firewall_policy_association = var.application_gateway.force_firewall_policy_association
  zones                             = var.application_gateway.zones

  identity {
    type = "UserAssigned"
    identity_ids = [
      var.identity_id
    ]
  }

  sku {
    name     = var.application_gateway.sku.name
    tier     = var.application_gateway.sku.tier
    capacity = var.application_gateway.sku.capacity
  }

  autoscale_configuration {
    min_capacity = var.application_gateway.autoscale_configuration.min_capacity
    max_capacity = var.application_gateway.autoscale_configuration.max_capacity
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                          = local.frontend_ip_configuration_name
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  frontend_port {
    name = "port_443"
    port = 443
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.backend_http_settings_name
    cookie_based_affinity = "Disabled"
    protocol              = "Http"
    port                  = 80
    request_timeout       = 20
    probe_name            = local.probe_name

    connection_draining {
      enabled           = true
      drain_timeout_sec = 60
    }
  }

  http_listener {
    name                           = local.http_listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = "port_80"
    protocol                       = "Http"
    require_sni                    = false
  }

  http_listener {
    name                           = local.https_listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = "port_443"
    protocol                       = "Https"
    require_sni                    = false
    ssl_certificate_name           = var.ssl_certificate_name
  }

  request_routing_rule {
    name                        = local.http_request_routing_rule_name
    redirect_configuration_name = local.http_request_routing_rule_name
    rule_type                   = "Basic"
    http_listener_name          = local.http_listener_name
    priority                    = 1
  }

  redirect_configuration {
    name                 = local.http_request_routing_rule_name
    target_listener_name = local.https_listener_name
    redirect_type        = "Permanent"
    include_path         = true
    include_query_string = true
  }

  request_routing_rule {
    name                       = local.https_request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.https_listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.backend_http_settings_name
    priority                   = 2
  }

  ssl_certificate {
    name                = var.ssl_certificate_name
    key_vault_secret_id = var.key_vault_secret_id
  }

  probe {
    name                = local.probe_name
    host                = "127.0.0.1"
    protocol            = "Http"
    path                = "/"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3

    match {
      status_code = [
        "200-399",
      ]
    }
  }

  tags = var.tags
}

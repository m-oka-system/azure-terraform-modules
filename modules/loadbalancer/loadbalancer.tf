#################################
# Load Balancer
################################
resource "azurerm_public_ip" "this" {
  name                = "pip-lb-${var.common.project}-${var.common.env}"
  resource_group_name = var.resource_group_name
  location            = var.common.location
  sku                 = var.loadbalancer.public_ip.sku
  allocation_method   = var.loadbalancer.public_ip.allocation_method
  zones               = var.loadbalancer.public_ip.zones

  tags = var.tags
}

resource "azurerm_lb" "this" {
  name                = "lb-${var.common.project}-${var.common.env}"
  resource_group_name = var.resource_group_name
  location            = var.common.location
  sku                 = var.loadbalancer.sku

  frontend_ip_configuration {
    name                 = var.loadbalancer.frontend_ip_name
    public_ip_address_id = azurerm_public_ip.this.id
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "this" {
  name            = var.loadbalancer.backend_pool_name
  loadbalancer_id = azurerm_lb.this.id
}

resource "azurerm_network_interface_backend_address_pool_association" "this" {
  for_each = var.network_interfaces

  ip_configuration_name   = "ipconfig1"
  network_interface_id    = each.value.id
  backend_address_pool_id = azurerm_lb_backend_address_pool.this.id
}

resource "azurerm_lb_probe" "this" {
  loadbalancer_id     = azurerm_lb.this.id
  name                = var.loadbalancer.probe.name
  port                = var.loadbalancer.probe.port
  interval_in_seconds = var.loadbalancer.probe.interval_in_seconds
  number_of_probes    = var.loadbalancer.probe.number_of_probes
  protocol            = var.loadbalancer.probe.protocol
  request_path        = var.loadbalancer.probe.request_path
}

resource "azurerm_lb_rule" "this" {
  name                           = var.loadbalancer.rule.name
  protocol                       = var.loadbalancer.rule.protocol
  frontend_port                  = var.loadbalancer.rule.frontend_port
  backend_port                   = var.loadbalancer.rule.backend_port
  frontend_ip_configuration_name = var.loadbalancer.rule.frontend_ip_configuration_name
  loadbalancer_id                = azurerm_lb.this.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this.id]
  probe_id                       = azurerm_lb_probe.this.id
  enable_floating_ip             = var.loadbalancer.rule.enable_floating_ip
  idle_timeout_in_minutes        = var.loadbalancer.rule.idle_timeout_in_minutes
  load_distribution              = var.loadbalancer.rule.load_distribution
  disable_outbound_snat          = var.loadbalancer.rule.disable_outbound_snat
  enable_tcp_reset               = var.loadbalancer.rule.enable_tcp_reset
}

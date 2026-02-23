output "loadbalancer" {
  value = azurerm_lb.this
}

output "loadbalancer_public_ip" {
  value = azurerm_public_ip.this
}

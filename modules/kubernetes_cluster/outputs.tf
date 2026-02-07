output "kubernetes_cluster" {
  value = azurerm_kubernetes_cluster.this
}

output "application_gateway_ingress" {
  value = azurerm_application_gateway.this
}

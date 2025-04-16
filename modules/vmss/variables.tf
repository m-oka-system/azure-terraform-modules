variable "common" {}
variable "resource_group_name" {}
variable "tags" {}
variable "vmss" {}
variable "vmss_admin_username" {}
variable "public_key" {}
variable "subnet" {}
variable "application_gateway_backend_address_pool_ids" {
  default = []
}
variable "load_balancer_backend_address_pool_ids" {
  default = []
}

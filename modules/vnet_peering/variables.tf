variable "resource_group_name" {
  description = "リソースグループ名"
  type        = string
  nullable    = false
}

variable "hub_vnet_name" {
  description = "Hub VNet の名前"
  type        = string
  nullable    = false
}

variable "hub_vnet_id" {
  description = "Hub VNet のリソース ID"
  type        = string
  nullable    = false
}

variable "spoke_vnet_name" {
  description = "Spoke VNet の名前"
  type        = string
  nullable    = false
}

variable "spoke_vnet_id" {
  description = "Spoke VNet のリソース ID"
  type        = string
  nullable    = false
}

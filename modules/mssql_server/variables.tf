variable "common" {}
variable "resource_group_name" {}
variable "tags" {}
variable "random" {}
variable "identity_id" {}
variable "firewall_rules" {}
variable "storage_endpoint" {}
variable "defender_for_cloud_enabled" {}
variable "azuread_authentication_only" {
  type        = bool
  description = "Microsoft Entra 認証のみとするかどうか"
  default     = true
}

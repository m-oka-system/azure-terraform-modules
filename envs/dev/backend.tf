terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate84501"
    container_name       = "terraform-state"
    key                  = "dev.terraform.tfstate"
  }
}

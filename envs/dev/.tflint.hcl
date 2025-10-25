tflint {
  required_version = ">= 0.59.1"
}

plugin "azurerm" {
  enabled = true
  version = "0.29.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

config {
  format           = "default"
  call_module_type = "local"
}

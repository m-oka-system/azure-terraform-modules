variable "common" {
  description = "プロジェクト共通設定"
  type = object({
    project  = string
    env      = string
    location = string
  })
  nullable = false
}

variable "resource_group_name" {
  description = "リソースグループ名"
  type        = string
  nullable    = false
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "vnet" {
  description = "仮想ネットワークの設定"
  type = map(object({
    name          = string
    address_space = list(string)
  }))
  default = {
    hub = {
      name          = "hub"
      address_space = ["192.168.0.0/16"]
    }
    spoke1 = {
      name          = "spoke1"
      address_space = ["10.10.0.0/16"]
    }
    spoke2 = {
      name          = "spoke2"
      address_space = ["10.20.0.0/16"]
    }
  }
  nullable = false
}

variable "subnet" {
  description = "サブネットの設定"
  type = map(object({
    name                              = string
    target_vnet                       = string
    address_prefixes                  = list(string)
    default_outbound_access_enabled   = optional(bool, false)
    private_endpoint_network_policies = optional(string, "Disabled")
    service_endpoints                 = optional(list(string), [])
    service_delegation = optional(object({
      name    = string
      actions = list(string)
    }))
  }))
  default = {
    bastion = {
      name             = "AzureBastionSubnet"
      target_vnet      = "hub"
      address_prefixes = ["192.168.1.0/24"]
    }
    pe = {
      name                              = "pe"
      target_vnet                       = "spoke1"
      address_prefixes                  = ["10.10.0.0/24"]
      private_endpoint_network_policies = "Enabled"
    }
    app = {
      name             = "app"
      target_vnet      = "spoke1"
      address_prefixes = ["10.10.1.0/24"]
      service_delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    func = {
      name             = "func"
      target_vnet      = "spoke1"
      address_prefixes = ["10.10.2.0/24"]
      service_delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    mysql = {
      name             = "mysql"
      target_vnet      = "spoke1"
      address_prefixes = ["10.10.3.0/24"]
      service_delegation = {
        name    = "Microsoft.DBforMySQL/flexibleServers"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
    vm = {
      name             = "vm"
      target_vnet      = "spoke1"
      address_prefixes = ["10.10.4.0/24"]
    }
    appgw = {
      name             = "appgw"
      target_vnet      = "spoke1"
      address_prefixes = ["10.10.5.0/24"]
      service_delegation = {
        name    = "Microsoft.Network/applicationGateways"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
    psql = {
      name              = "psql"
      target_vnet       = "spoke1"
      address_prefixes  = ["10.10.6.0/24"]
      service_endpoints = ["Microsoft.Storage"] # PostgreSQL Flexible Server が WAL ファイルを Azure Storage にアーカイブするために必要
      service_delegation = {
        name    = "Microsoft.DBforPostgreSQL/flexibleServers"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
    cae = {
      name             = "cae"
      target_vnet      = "spoke1"
      address_prefixes = ["10.10.11.0/24"]
      service_delegation = {
        name    = "Microsoft.App/environments"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
    aks = {
      name             = "aks"
      target_vnet      = "spoke1"
      address_prefixes = ["10.10.12.0/24"]
    }
    vm2 = {
      name             = "vm2"
      target_vnet      = "spoke2"
      address_prefixes = ["10.20.4.0/24"]
    }
  }
  nullable = false
}

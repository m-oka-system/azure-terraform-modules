variable "common" {
  type = map(string)
  default = {
    project  = "terraform"
    env      = "dev"
    location = "japaneast"
  }
}

variable "vnet" {
  type = map(object({
    name          = string
    address_space = list(string)
  }))
  default = {
    spoke1 = {
      name          = "spoke1"
      address_space = ["10.10.0.0/16"]
    }
  }
}

variable "subnet" {
  type = map(object({
    name                              = string
    target_vnet                       = string
    address_prefixes                  = list(string)
    default_outbound_access_enabled   = bool
    private_endpoint_network_policies = string
    service_delegation = object({
      name    = string
      actions = list(string)
    })
  }))
  default = {
    pe = {
      name                              = "pe"
      target_vnet                       = "spoke1"
      address_prefixes                  = ["10.10.0.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Enabled"
      service_delegation                = null
    }
    app = {
      name                              = "app"
      target_vnet                       = "spoke1"
      address_prefixes                  = ["10.10.1.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Disabled"
      service_delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    function = {
      name                              = "function"
      target_vnet                       = "spoke1"
      address_prefixes                  = ["10.10.2.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Disabled"
      service_delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    db = {
      name                              = "db"
      target_vnet                       = "spoke1"
      address_prefixes                  = ["10.10.3.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Disabled"
      service_delegation = {
        name    = "Microsoft.DBforMySQL/flexibleServers"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
    vm = {
      name                              = "vm"
      target_vnet                       = "spoke1"
      address_prefixes                  = ["10.10.4.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Disabled"
      service_delegation                = null
    }
  }
}

variable "network_security_group" {
  type = map(object({
    name          = string
    target_subnet = string
  }))
  default = {
    pe = {
      name          = "pe"
      target_subnet = "pe"
    }
    app = {
      name          = "app"
      target_subnet = "app"
    }
    function = {
      name          = "function"
      target_subnet = "function"
    }
    db = {
      name          = "db"
      target_subnet = "db"
    }
    vm = {
      name          = "vm"
      target_subnet = "vm"
    }
  }
}

variable "network_security_rule" {
  type = list(object({
    target_nsg                   = string
    name                         = string
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = optional(string)
    source_port_ranges           = optional(list(string))
    destination_port_range       = optional(string)
    destination_port_ranges      = optional(list(string))
    source_address_prefix        = optional(string)
    source_address_prefixes      = optional(list(string))
    destination_address_prefix   = optional(string)
    destination_address_prefixes = optional(list(string))
  }))

  # 単数・複数の排他的なパラメータはどちらか一方を指定する
  validation {
    condition = alltrue([
      for rule in var.network_security_rule :
      (rule.source_port_range != null && rule.source_port_ranges == null) ||
      (rule.source_port_range == null && rule.source_port_ranges != null)
    ])
    error_message = "送信元ポートは単数(source_port_range)または複数(source_port_ranges)のどちらか一方のみ指定してください。"
  }

  validation {
    condition = alltrue([
      for rule in var.network_security_rule :
      (rule.destination_port_range != null && rule.destination_port_ranges == null) ||
      (rule.destination_port_range == null && rule.destination_port_ranges != null)
    ])
    error_message = "宛先ポートは単数(destination_port_range)または複数(destination_port_ranges)のどちらか一方のみ指定してください。"
  }

  validation {
    condition = alltrue([
      for rule in var.network_security_rule :
      (rule.source_address_prefix != null && rule.source_address_prefixes == null) ||
      (rule.source_address_prefix == null && rule.source_address_prefixes != null)
    ])
    error_message = "送信元アドレスは単数(source_address_prefix)または複数(source_address_prefixes)のどちらか一方のみ指定してください。"
  }

  validation {
    condition = alltrue([
      for rule in var.network_security_rule :
      (rule.destination_address_prefix != null && rule.destination_address_prefixes == null) ||
      (rule.destination_address_prefix == null && rule.destination_address_prefixes != null)
    ])
    error_message = "宛先アドレスは単数(destination_address_prefix)または複数(destination_address_prefixes)のどちらか一方のみ指定してください。"
  }

  default = [
    # PE Subnet
    {
      target_nsg                 = "pe"
      name                       = "AllowAppSubnetHTTPSInbound"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "10.10.1.0/24"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "pe"
      name                       = "AllowFunctionSubnetHTTPSInbound"
      priority                   = 1100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "10.10.2.0/24"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "pe"
      name                       = "DenyAllInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "pe"
      name                       = "DenyAllOutbound"
      priority                   = 4096
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    # App Subnet
    {
      target_nsg                 = "app"
      name                       = "AllowPeSubnetHTTPSOutbound"
      priority                   = 1000
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "10.10.0.0/24"
    },
    {
      target_nsg                 = "app"
      name                       = "AllowDbSubnetMySQLOutbound"
      priority                   = 1100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3306"
      source_address_prefix      = "*"
      destination_address_prefix = "10.10.3.0/24"
    },
    {
      target_nsg                 = "app"
      name                       = "AllowInternetOutbound"
      priority                   = 1200
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    },
    {
      target_nsg                 = "app"
      name                       = "DenyAllOutbound"
      priority                   = 4096
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    # Function Subnet
    {
      target_nsg                 = "function"
      name                       = "AllowPeSubnetHTTPSOutbound"
      priority                   = 1000
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "10.10.0.0/24"
    },
    {
      target_nsg                 = "function"
      name                       = "AllowInternetOutbound"
      priority                   = 1100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    },
    {
      target_nsg                 = "function"
      name                       = "DenyAllOutbound"
      priority                   = 4096
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    # DB Subnet
    {
      target_nsg                 = "db"
      name                       = "AllowAppSubnetMySQLInbound"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3306"
      source_address_prefix      = "10.10.1.0/24"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "db"
      name                       = "AllowVmSubnetMySQLInbound"
      priority                   = 1100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3306"
      source_address_prefix      = "10.10.4.0/24"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "db"
      name                       = "DenyAllInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "db"
      name                       = "DenyAllOutbound"
      priority                   = 4096
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    # VM Subnet
    {
      target_nsg                 = "vm"
      name                       = "AllowSshRdpInbound"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["22", "3389"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "vm"
      name                       = "AllowDbSubnetMySQLOutbound"
      priority                   = 1000
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3306"
      source_address_prefix      = "*"
      destination_address_prefix = "10.10.3.0/24"
    },
    {
      target_nsg                 = "vm"
      name                       = "AllowInternetOutbound"
      priority                   = 1100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    },
    {
      target_nsg                 = "vm"
      name                       = "DenyAllInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "vm"
      name                       = "DenyAllOutbound"
      priority                   = 4096
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
  ]
}

variable "common" {
  type = object({
    project  = string
    env      = string
    location = string
  })
  default = {
    project  = "terraform"
    env      = "dev"
    location = "japaneast"
  }
}

# 特定の Azure リソースを作成する/しないフラグ
variable "resource_enabled" {
  type = object({
    activity_log          = optional(bool, false)
    dns_zone              = optional(bool, false)
    private_dns_zone      = optional(bool, false)
    private_endpoint      = optional(bool, false)
    custom_domain         = optional(bool, false)
    frontdoor             = optional(bool, false)
    frontdoor_waf         = optional(bool, false)
    container_registry    = optional(bool, false)
    container_app         = optional(bool, false)
    kubernetes_cluster    = optional(bool, false)
    app_service_plan      = optional(bool, false)
    app_service           = optional(bool, false)
    function              = optional(bool, false)
    aisearch              = optional(bool, false)
    cosmosdb              = optional(bool, false)
    mysql                 = optional(bool, false)
    postgresql            = optional(bool, false)
    mssql_database        = optional(bool, false)
    redis                 = optional(bool, false)
    vm                    = optional(bool, false)
    vmss                  = optional(bool, false)
    loadbalancer          = optional(bool, false)
    bastion               = optional(bool, false)
    nat_gateway           = optional(bool, false)
    resource_health_alert = optional(bool, false)
    diagnostic_setting    = optional(bool, false)
    backup_vault          = optional(bool, false)
    defender_for_cloud    = optional(bool, false)
  })
  default = {}
}

variable "allowed_cidr" {
  type    = string
  default = "203.0.113.10,203.0.113.11"
}

variable "vnet" {
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
}

variable "subnet" {
  type = map(object({
    name                              = string
    target_vnet                       = string
    address_prefixes                  = list(string)
    default_outbound_access_enabled   = bool
    private_endpoint_network_policies = string
    service_endpoints                 = optional(list(string), [])
    service_delegation = optional(object({
      name    = string
      actions = list(string)
    }))
  }))
  default = {
    bastion = {
      name                              = "AzureBastionSubnet"
      target_vnet                       = "hub"
      address_prefixes                  = ["192.168.1.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Disabled"
    }
    pe = {
      name                              = "pe"
      target_vnet                       = "spoke1"
      address_prefixes                  = ["10.10.0.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Enabled"
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
    func = {
      name                              = "func"
      target_vnet                       = "spoke1"
      address_prefixes                  = ["10.10.2.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Disabled"
      service_delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    mysql = {
      name                              = "mysql"
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
    }
    appgw = {
      name                              = "appgw"
      target_vnet                       = "spoke1"
      address_prefixes                  = ["10.10.5.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Disabled"
      service_delegation = {
        name    = "Microsoft.Network/applicationGateways"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
    psql = {
      name                              = "psql"
      target_vnet                       = "spoke1"
      address_prefixes                  = ["10.10.6.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Disabled"
      service_endpoints                 = ["Microsoft.Storage"] # PostgreSQL Flexible Server が WAL ファイルを Azure Storage にアーカイブするために必要
      service_delegation = {
        name    = "Microsoft.DBforPostgreSQL/flexibleServers"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
    cae = {
      name                              = "cae"
      target_vnet                       = "spoke1"
      address_prefixes                  = ["10.10.11.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Disabled"
      service_delegation = {
        name    = "Microsoft.App/environments"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
    aks = {
      name                              = "aks"
      target_vnet                       = "spoke1"
      address_prefixes                  = ["10.10.12.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Disabled"
    }
    # Spoke2
    vm2 = {
      name                              = "vm2"
      target_vnet                       = "spoke2"
      address_prefixes                  = ["10.20.4.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Disabled"
    }
  }
}

variable "network_security_group" {
  type = map(object({
    name          = string
    target_subnet = string
  }))
  default = {
    bastion = {
      name          = "bastion"
      target_subnet = "bastion"
    }
    pe = {
      name          = "pe"
      target_subnet = "pe"
    }
    app = {
      name          = "app"
      target_subnet = "app"
    }
    func = {
      name          = "func"
      target_subnet = "func"
    }
    mysql = {
      name          = "mysql"
      target_subnet = "mysql"
    }
    vm = {
      name          = "vm"
      target_subnet = "vm"
    }
    appgw = {
      name          = "appgw"
      target_subnet = "appgw"
    }
    psql = {
      name          = "psql"
      target_subnet = "psql"
    }
    cae = {
      name          = "cae"
      target_subnet = "cae"
    }
    aks = {
      name          = "aks"
      target_subnet = "aks"
    }
    # Spoke2
    vm2 = {
      name          = "vm2"
      target_subnet = "vm2"
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
    # AzureBastionSubnet
    {
      target_nsg                 = "bastion"
      name                       = "AllowHttpsInbound"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "bastion"
      name                       = "AllowGatewayManagerInbound"
      priority                   = 1100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "GatewayManager"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "bastion"
      name                       = "AllowAzureLoadBalancerInbound"
      priority                   = 1200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "bastion"
      name                       = "AllowBastionHostCommunication"
      priority                   = 1300
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["8080", "5701"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      target_nsg                 = "bastion"
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
      target_nsg                 = "bastion"
      name                       = "AllowSshRdpOutbound"
      priority                   = 1000
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["22", "3389"]
      source_address_prefix      = "*"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      target_nsg                 = "bastion"
      name                       = "AllowAzureCloudOutbound"
      priority                   = 1100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "AzureCloud"
    },
    {
      target_nsg                 = "bastion"
      name                       = "AllowBastionCommunication"
      priority                   = 1200
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["8080", "5701"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      target_nsg                 = "bastion"
      name                       = "AllowHttpOutbound"
      priority                   = 1300
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    },
    {
      target_nsg                 = "bastion"
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
      name                       = "AllowFuncSubnetHTTPSInbound"
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
      name                       = "AllowAksSubnetHTTPSInbound"
      priority                   = 1200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "10.10.12.0/24"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "pe"
      name                       = "AllowAksSubnetSQLInbound"
      priority                   = 1300
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "1433"
      source_address_prefix      = "10.10.12.0/24"
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
      target_nsg                 = "func"
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
      target_nsg                 = "func"
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
      target_nsg                 = "func"
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
    # MySQL Subnet
    {
      target_nsg                 = "mysql"
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
      target_nsg                 = "mysql"
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
      target_nsg                 = "mysql"
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
      target_nsg                 = "mysql"
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
      name                       = "AllowHttpInbound"
      priority                   = 1100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
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
    # Application Gateway Subnet
    {
      target_nsg                 = "appgw"
      name                       = "AllowGatewayManagerInbound"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "65200-65535"
      source_address_prefix      = "GatewayManager"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "appgw"
      name                       = "AllowAzureLoadBalancerInbound"
      priority                   = 1100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "appgw"
      name                       = "AllowInternetHTTPInbound"
      priority                   = 1200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "appgw"
      name                       = "AllowInternetHTTPSInbound"
      priority                   = 1300
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "appgw"
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
    # PostgreSQL Subnet
    {
      target_nsg                 = "psql"
      name                       = "AllowAppSubnetPostgreSQLInbound"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "5432"
      source_address_prefix      = "10.10.1.0/24"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "psql"
      name                       = "AllowVmSubnetPostgreSQLInbound"
      priority                   = 1100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "5432"
      source_address_prefix      = "10.10.4.0/24"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "psql"
      name                       = "AllowAksSubnetPostgreSQLInbound"
      priority                   = 1200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "5432"
      source_address_prefix      = "10.10.12.0/24"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "psql"
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
      target_nsg                 = "psql"
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
    # AKS
    {
      target_nsg                 = "aks"
      name                       = "AllowInternetHTTPInbound"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "aks"
      name                       = "AllowInternetHTTPSInbound"
      priority                   = 1100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
  ]
}

variable "storage" {
  type = map(object({
    name                            = string
    account_tier                    = string
    account_kind                    = string
    account_replication_type        = string
    access_tier                     = string
    https_traffic_only_enabled      = optional(bool, true) # 安全な転送が必須
    public_network_access_enabled   = bool
    shared_access_key_enabled       = bool # ストレージ アカウント キーへのアクセスを許可する
    default_to_oauth_authentication = bool # Azure portal で Microsoft Entra 認可を既定にする
    is_hns_enabled                  = bool
    defender_for_storage_enabled    = bool # Defender for Storageを有効にするかどうか
    blob_properties = object({
      versioning_enabled                = bool
      change_feed_enabled               = bool
      change_feed_retention_in_days     = optional(number) # 変更フィードの保持期間 (日数) （nullの場合は無期限）
      last_access_time_enabled          = bool
      delete_retention_policy           = number # 削除した BLOB の保持期間 (日数)
      container_delete_retention_policy = number # 削除したコンテナーの保持期間 (日数)
      restore_policy = optional(object({         # ポイントインタイムリストアのポリシー（nullの場合は無効化）
        days = number                            # ポイントインタイムリストアの最大復元ポイント (経過日数)
      }))
    })
    network_rules = optional(object({
      default_action             = string
      bypass                     = list(string)
      ip_rules                   = list(string)
      virtual_network_subnet_ids = list(string)
    }))
    immutability_policy = optional(object({
      allow_protected_append_writes = bool   # 保護された追加書き込みを許可するかどうか
      period_since_creation_in_days = number # 不変期間（日数）- 1から146000 (400年) の範囲
      state                         = string # 不変性ポリシーの状態: "Unlocked"（編集可能）または "Locked"（ロック済み）
    }))
    static_website_enabled = optional(bool, false)
    static_website_config = optional(object({
      index_document     = string
      error_404_document = string
    }))
  }))
  default = {
    app = {
      name                            = "app"
      account_tier                    = "Standard"
      account_kind                    = "StorageV2"
      account_replication_type        = "LRS"
      access_tier                     = "Hot"
      public_network_access_enabled   = true
      shared_access_key_enabled       = false
      default_to_oauth_authentication = true
      is_hns_enabled                  = false
      defender_for_storage_enabled    = false
      blob_properties = {
        versioning_enabled                = true
        change_feed_enabled               = true
        change_feed_retention_in_days     = 12
        last_access_time_enabled          = false
        delete_retention_policy           = 12
        container_delete_retention_policy = 7
        restore_policy = {
          days = 7
        }
      }
      network_rules = {
        default_action             = "Deny"
        bypass                     = ["AzureServices"]
        ip_rules                   = ["MyIP"]
        virtual_network_subnet_ids = []
      }
    }
    web = {
      name                            = "web"
      account_tier                    = "Standard"
      account_kind                    = "StorageV2"
      account_replication_type        = "LRS"
      access_tier                     = "Hot"
      public_network_access_enabled   = true
      shared_access_key_enabled       = false
      default_to_oauth_authentication = true
      is_hns_enabled                  = false
      defender_for_storage_enabled    = false
      blob_properties = {
        versioning_enabled                = true
        change_feed_enabled               = true
        change_feed_retention_in_days     = 12
        last_access_time_enabled          = false
        delete_retention_policy           = 12
        container_delete_retention_policy = 7
        restore_policy = {
          days = 7
        }
      }
      network_rules          = null
      static_website_enabled = true
      static_website_config = {
        index_document     = "index.html"
        error_404_document = "404.html"
      }
    }
    func = {
      name                            = "func"
      account_tier                    = "Standard"
      account_kind                    = "StorageV2"
      account_replication_type        = "LRS"
      access_tier                     = "Hot"
      public_network_access_enabled   = true
      shared_access_key_enabled       = false
      default_to_oauth_authentication = true
      is_hns_enabled                  = false
      defender_for_storage_enabled    = false
      blob_properties = {
        versioning_enabled                = false
        change_feed_enabled               = false
        last_access_time_enabled          = false
        delete_retention_policy           = 7
        container_delete_retention_policy = 7
        restore_policy                    = null
      }
      network_rules = {
        default_action             = "Deny"
        bypass                     = ["AzureServices"]
        ip_rules                   = ["MyIP"]
        virtual_network_subnet_ids = []
      }
    }
    log = {
      name                            = "log"
      account_tier                    = "Standard"
      account_kind                    = "StorageV2"
      account_replication_type        = "LRS"
      access_tier                     = "Hot"
      public_network_access_enabled   = true
      shared_access_key_enabled       = false
      default_to_oauth_authentication = true
      is_hns_enabled                  = false
      defender_for_storage_enabled    = false
      blob_properties = {
        versioning_enabled                = true
        change_feed_enabled               = false
        last_access_time_enabled          = false
        delete_retention_policy           = 7
        container_delete_retention_policy = 7
        restore_policy                    = null
      }
      network_rules = {
        default_action             = "Deny"
        bypass                     = ["AzureServices"]
        ip_rules                   = ["MyIP"]
        virtual_network_subnet_ids = []
      }
      immutability_policy = {
        allow_protected_append_writes = true
        period_since_creation_in_days = 1
        state                         = "Unlocked"
      }
    }
  }
}

variable "blob_container" {
  type = map(map(string))
  default = {
    app_static = {
      target_storage_account = "app"
      container_name         = "static"
      container_access_type  = "private"
    }
    app_media = {
      target_storage_account = "app"
      container_name         = "media"
      container_access_type  = "private"
    }
  }
}

variable "storage_management_policy" {
  type = map(object({
    name                   = string
    target_storage_account = string
    blob_types             = list(string)
    actions = object({
      base_blob = optional(object({
        auto_tier_to_hot_from_cool_enabled                             = optional(bool)
        delete_after_days_since_creation_greater_than                  = optional(number)
        delete_after_days_since_last_access_time_greater_than          = optional(number)
        delete_after_days_since_modification_greater_than              = optional(number)
        tier_to_archive_after_days_since_creation_greater_than         = optional(number)
        tier_to_archive_after_days_since_last_access_time_greater_than = optional(number)
        tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
        tier_to_archive_after_days_since_modification_greater_than     = optional(number)
        tier_to_cold_after_days_since_creation_greater_than            = optional(number)
        tier_to_cold_after_days_since_last_access_time_greater_than    = optional(number)
        tier_to_cold_after_days_since_modification_greater_than        = optional(number)
        tier_to_cool_after_days_since_creation_greater_than            = optional(number)
        tier_to_cool_after_days_since_last_access_time_greater_than    = optional(number)
        tier_to_cool_after_days_since_modification_greater_than        = optional(number)
      }))
      snapshot = optional(object({
        change_tier_to_archive_after_days_since_creation               = optional(number)
        change_tier_to_cool_after_days_since_creation                  = optional(number)
        delete_after_days_since_creation_greater_than                  = optional(number)
        tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
        tier_to_cold_after_days_since_creation_greater_than            = optional(number)
      }))
      version = optional(object({
        change_tier_to_archive_after_days_since_creation               = optional(number)
        change_tier_to_cool_after_days_since_creation                  = optional(number)
        delete_after_days_since_creation                               = optional(number)
        tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
        tier_to_cold_after_days_since_creation_greater_than            = optional(number)
      }))
    })
  }))
  default = {
    app = {
      name                   = "delete-after-7-days"
      target_storage_account = "app"
      blob_types             = ["blockBlob", "appendBlob"]
      actions = {
        base_blob = {
          delete_after_days_since_modification_greater_than = 7
        }
        snapshot = {
          delete_after_days_since_creation_greater_than = 7
        }
        version = {
          delete_after_days_since_creation = 7
        }
      }
    }
    # リソースログ (診断設定) は appendBlob として記録される
    # appendBlob はアクセス層をサポートしていない (削除のみ可能)
    log = {
      name                   = "delete-after-1-day"
      target_storage_account = "log"
      blob_types             = ["appendBlob"]
      actions = {
        base_blob = {
          delete_after_days_since_modification_greater_than = 1
        }
        snapshot = {
          delete_after_days_since_creation_greater_than = 1
        }
        version = {
          delete_after_days_since_creation = 1
        }
      }
    }
  }
}

variable "key_vault" {
  type = map(object({
    name                       = string
    sku_name                   = string
    rbac_authorization_enabled = bool
    purge_protection_enabled   = bool
    soft_delete_retention_days = number
    network_acls = object({
      default_action             = string
      bypass                     = string
      ip_rules                   = list(string)
      virtual_network_subnet_ids = list(string)
    })
  }))
  default = {
    app = {
      name                       = "app"
      sku_name                   = "standard"
      rbac_authorization_enabled = true
      purge_protection_enabled   = false
      soft_delete_retention_days = 7
      network_acls = {
        default_action             = "Deny"
        bypass                     = "AzureServices"
        ip_rules                   = ["MyIP"]
        virtual_network_subnet_ids = []
      }
    }
  }
}

variable "log_analytics" {
  type = map(object({
    sku                             = string
    allow_resource_only_permissions = bool
    local_authentication_enabled    = bool
    retention_in_days               = number
    internet_ingestion_enabled      = bool
    internet_query_enabled          = bool
  }))
  default = {
    logs = {
      sku                             = "PerGB2018"
      allow_resource_only_permissions = false
      local_authentication_enabled    = false
      retention_in_days               = 30
      internet_ingestion_enabled      = false
      internet_query_enabled          = true
    }
  }
}

variable "application_insights" {
  type = map(object({
    name                       = string
    application_type           = string
    target_workspace           = string
    retention_in_days          = number
    internet_ingestion_enabled = bool
    internet_query_enabled     = bool
  }))
  default = {
    app = {
      name                       = "app"
      target_workspace           = "logs"
      application_type           = "web"
      retention_in_days          = 90
      internet_ingestion_enabled = false
      internet_query_enabled     = true
    }
    func = {
      name                       = "func"
      target_workspace           = "logs"
      application_type           = "web"
      retention_in_days          = 90
      internet_ingestion_enabled = false
      internet_query_enabled     = true
    }
  }
}

variable "user_assigned_identity" {
  type = map(object({
    name = string
  }))
  default = {
    app = {
      name = "app"
    }
    func = {
      name = "func"
    }
    appgw = {
      name = "appgw"
    }
    mssql = {
      name = "mssql"
    }
    gha = {
      name = "gha"
    }
    k8s = {
      name = "k8s"
    }
  }
}

variable "role_assignment" {
  type = map(object({
    target_identity      = string
    role_definition_name = string
  }))
  default = {
    app_acr_pull = {
      target_identity      = "app"
      role_definition_name = "AcrPull"
    }
    app_key_vault_secrets_user = {
      target_identity      = "app"
      role_definition_name = "Key Vault Secrets User"
    }
    app_storage_blob_data_contributor = {
      target_identity      = "app"
      role_definition_name = "Storage Blob Data Contributor"
    }
    func_acr_pull = {
      target_identity      = "func"
      role_definition_name = "AcrPull"
    }
    func_key_vault_secrets_user = {
      target_identity      = "func"
      role_definition_name = "Key Vault Secrets User"
    }
    appgw_key_vault_secrets_user = {
      target_identity      = "appgw"
      role_definition_name = "Key Vault Secrets User"
    }
    mssql_blob_data_contributor = {
      target_identity      = "mssql"
      role_definition_name = "Storage Blob Data Contributor"
    }
    gha_contributor = {
      target_identity      = "gha"
      role_definition_name = "Contributor"
    }
    gha_key_vault_secrets_user = {
      target_identity      = "gha"
      role_definition_name = "Key Vault Secrets User"
    }
    gha_storage_blob_data_contributor = {
      target_identity      = "gha"
      role_definition_name = "Storage Blob Data Contributor"
    }
    k8s_key_vault_secrets_user = {
      target_identity      = "k8s"
      role_definition_name = "Key Vault Secrets User"
    }
  }
}

variable "custom_domain" {
  type = map(object({
    dns_zone_name             = string
    subdomain                 = string
    target_frontdoor_endpoint = string
  }))
  default = {
    app = {
      dns_zone_name             = "azphoto.xyz"
      subdomain                 = "www"
      target_frontdoor_endpoint = "app"
    }
  }
}

variable "private_dns_zone" {
  type = map(string)
  default = {
    blob      = "privatelink.blob.core.windows.net"
    key_vault = "privatelink.vaultcore.azure.net"
    # Azure Monitor Private Link Scope (AMPLS) のプライベート DNS ゾーン
    monitor  = "privatelink.monitor.azure.com"
    oms      = "privatelink.oms.opinsights.azure.com"
    ods      = "privatelink.ods.opinsights.azure.com"
    agentsvc = "privatelink.agentsvc.azure-automation.net"
  }
}

variable "private_link_scope" {
  type = map(object({
    name                  = string
    ingestion_access_mode = string
    query_access_mode     = string
  }))
  default = {
    app = {
      name                  = "app"
      ingestion_access_mode = "Open"
      query_access_mode     = "Open"
    }
  }
}

variable "frontdoor_profile" {
  type = object({
    sku_name                 = string # Standard_AzureFrontDoor, Premium_AzureFrontDoor
    response_timeout_seconds = number
  })
  default = {
    sku_name                 = "Standard_AzureFrontDoor"
    response_timeout_seconds = 60
  }
}

variable "frontdoor_security_headers" {
  description = <<-EOT
    Front Door で追加するセキュリティヘッダーの設定。
    キーにヘッダー名、値に action (Overwrite/Append/Delete) と value を指定。

    推奨値 (OWASP/Chrome):
    - Strict-Transport-Security: "max-age=31536000; includeSubDomains" (1年間 HTTPS を強制)
    - X-Frame-Options: "DENY" (すべての iframe 埋め込みを禁止)
    - X-Content-Type-Options: "nosniff" (MIME スニッフィング防止)
    - Referrer-Policy: "strict-origin-when-cross-origin" (クロスオリジン時はオリジンのみ送信)
  EOT
  type = map(object({
    action = string
    value  = string
  }))
  default = {
    "Strict-Transport-Security" = {
      action = "Overwrite"
      value  = "max-age=31536000; includeSubDomains"
    }
    "X-Frame-Options" = {
      action = "Overwrite"
      value  = "DENY"
    }
    "X-Content-Type-Options" = {
      action = "Overwrite"
      value  = "nosniff"
    }
    "Referrer-Policy" = {
      action = "Overwrite"
      value  = "strict-origin-when-cross-origin"
    }
  }
}

variable "frontdoor_firewall_policy" {
  type = map(object({
    mode = string # Detection（検出のみ） または Prevention（防御）
    custom_rules = list(object({
      name                           = string
      type                           = string
      priority                       = number
      action                         = string
      rate_limit_duration_in_minutes = optional(number)
      rate_limit_threshold           = optional(number)
      match_conditions = list(object({
        match_variable     = string
        match_values       = list(string)
        operator           = string
        selector           = optional(string)
        negation_condition = optional(bool)
        transforms         = optional(list(string))
      }))
    }))
    managed_rules = optional(list(object({
      type    = string
      version = string
      action  = string
    })))
  }))
  default = {
    api = {
      mode = "Prevention"
      custom_rules = [
        {
          name     = "AllowMyIP"
          type     = "MatchRule"
          priority = 100
          action   = "Allow"
          match_conditions = [
            {
              match_variable = "RemoteAddr"
              match_values   = ["203.0.113.10/32"] # 例: 実際の環境では許可する IP アドレスに変更すること
              operator       = "IPMatch"
            }
          ]
        },
        {
          name                           = "RateLimitRule"
          type                           = "RateLimitRule"
          priority                       = 200
          action                         = "Block"
          rate_limit_duration_in_minutes = 1
          rate_limit_threshold           = 100
          match_conditions = [
            {
              match_variable = "RequestHeader"
              match_values   = ["0"]
              operator       = "GreaterThanOrEqual"
              selector       = "Host"
            }
          ]
        },
      ]
      managed_rules = [
        {
          type    = "Microsoft_DefaultRuleSet"
          version = "2.1"
          action  = "Block"
        }
      ]
    },
    front = {
      mode          = "Prevention"
      custom_rules  = []
      managed_rules = []
    }
    web = {
      mode          = "Prevention"
      custom_rules  = []
      managed_rules = []
    }
  }
}

variable "container_registry" {
  type = map(object({
    sku_name                      = string
    admin_enabled                 = bool
    public_network_access_enabled = bool
    zone_redundancy_enabled       = bool
  }))
  default = {
    app = {
      sku_name                      = "Basic"
      admin_enabled                 = false
      public_network_access_enabled = true
      zone_redundancy_enabled       = false
    }
  }
}

variable "container_app_environment" {
  type = map(object({
    name                           = string
    zone_redundancy_enabled        = bool
    logs_destination               = string
    target_subnet                  = string
    target_log_analytics_workspace = string
    workload_profile = object({
      name                  = string
      workload_profile_type = string
      minimum_count         = number
      maximum_count         = number
    })
  }))
  default = {
    app = {
      name                           = "app"
      zone_redundancy_enabled        = true
      logs_destination               = "log-analytics"
      target_subnet                  = "cae"
      target_log_analytics_workspace = "logs"
      workload_profile = {
        name                  = "Consumption"
        workload_profile_type = "Consumption"
        # Consumption の場合は 0 にする
        minimum_count = 0
        maximum_count = 0
      }
    }
  }
}

variable "container_app" {
  type = map(object({
    name                             = string
    target_container_app_environment = string
    target_user_assigned_identity    = string
    target_container_registry        = string
    workload_profile_name            = string
    revision_mode                    = string
    template = object({
      min_replicas = number
      max_replicas = number
      container = object({
        name   = string
        cpu    = number
        memory = string
      })
      http_scale_rule = object({
        name                = string
        concurrent_requests = number
      })
    })
    ingress = object({
      external_enabled           = bool
      allow_insecure_connections = bool
      client_certificate_mode    = string
      transport                  = string
      target_port                = number
      ip_security_restriction = object({
        name   = string
        action = string
      })
      traffic_weight = object({
        latest_revision = bool
        percentage      = number
      })
    })
  }))
  default = {
    app = {
      name                             = "app"
      target_container_app_environment = "app"
      target_user_assigned_identity    = "app"
      target_container_registry        = "app"
      workload_profile_name            = "Consumption"
      revision_mode                    = "Single"
      template = {
        min_replicas = 0
        max_replicas = 10
        container = {
          name   = "app"
          cpu    = 0.25
          memory = "0.5Gi"
        }
        http_scale_rule = {
          name                = "http-scale"
          concurrent_requests = 100
        }
      }
      ingress = {
        external_enabled           = true
        allow_insecure_connections = false
        client_certificate_mode    = "ignore"
        transport                  = "auto"
        target_port                = 50505
        ip_security_restriction = {
          name   = "AllowMyIP"
          action = "Allow"
        }
        traffic_weight = {
          latest_revision = true
          percentage      = 100
        }
      }
    }
  }
}

variable "kubernetes_cluster" {
  type = object({
    sku_tier                     = string
    kubernetes_version           = string
    local_account_disabled       = bool
    oidc_issuer_enabled          = bool
    workload_identity_enabled    = bool
    image_cleaner_enabled        = bool
    image_cleaner_interval_hours = number
    key_vault_secrets_provider = optional(object({
      secret_rotation_enabled  = bool
      secret_rotation_interval = string
    }), null)
    default_node_pool = object({
      vm_size              = string
      auto_scaling_enabled = bool
      min_count            = number
      max_count            = number
    })
    ingress_application_gateway = optional(object({
      sku = string
    }), null)
  })
  default = {
    sku_tier                     = "Standard"
    kubernetes_version           = "1.33"
    local_account_disabled       = false # Kubernetes RBAC を使用したローカルアカウントを使用する
    oidc_issuer_enabled          = true  # OIDC を有効にする
    workload_identity_enabled    = true  # ワークロード ID を有効にする
    image_cleaner_enabled        = true  # イメージクリーナーを有効にする
    image_cleaner_interval_hours = 168   # イメージクリーナーの間隔 （時間） (7日)
    key_vault_secrets_provider = {
      secret_rotation_enabled  = true # シークレットのローテーションを有効にする
      secret_rotation_interval = "2m" # シークレットのローテーション間隔
    }
    default_node_pool = {
      vm_size              = "Standard_D2pds_v6" # Arm64
      auto_scaling_enabled = true
      min_count            = 1
      max_count            = 3
    }
    ingress_application_gateway = {
      sku = "Standard_v2"
    }
  }
}

variable "app_service_plan" {
  type = map(object({
    name     = string
    os_type  = string
    sku_name = string
  }))
  default = {
    app = {
      name     = "app"
      os_type  = "Linux"
      sku_name = "B1"
    }
    # func = {
    #   name     = "func"
    #   os_type  = "Linux"
    #   sku_name = "B1"
    # }
  }
}

variable "app_service" {
  type = map(object({
    name                          = string
    target_service_plan           = string
    target_subnet                 = string
    target_user_assigned_identity = string
    public_network_access_enabled = bool
    site_config = object({
      container_registry_use_managed_identity = bool
      cors = optional(object({
        support_credentials = bool
      }))
    })
    ip_restriction = map(object({
      name        = string
      priority    = number
      action      = string
      ip_address  = string
      service_tag = string
    }))
    scm_ip_restriction = map(object({
      name        = string
      priority    = number
      action      = string
      ip_address  = string
      service_tag = string
    }))
  }))
  default = {
    api = {
      name                          = "api"
      target_service_plan           = "app"
      target_subnet                 = "app"
      target_user_assigned_identity = "app"
      public_network_access_enabled = true
      site_config = {
        container_registry_use_managed_identity = true
        cors = {
          support_credentials = true
        }
      }
      ip_restriction = {
        frontdoor = {
          name        = "AllowFrontDoor"
          priority    = 100
          action      = "Allow"
          ip_address  = null
          service_tag = "AzureFrontDoor.Backend"
        }
        myip = {
          name        = "AllowMyIP"
          priority    = 200
          action      = "Allow"
          ip_address  = "MyIP"
          service_tag = null
        }
      }
      scm_ip_restriction = {
        devops = {
          name        = "AllowDevOps"
          priority    = 100
          action      = "Allow"
          ip_address  = null
          service_tag = "AzureCloud"
        }
        myip = {
          name        = "AllowMyIP"
          priority    = 200
          action      = "Allow"
          ip_address  = "MyIP"
          service_tag = null
        }
      }
    }
    front = {
      name                          = "front"
      target_service_plan           = "app"
      target_subnet                 = "app"
      target_user_assigned_identity = "app"
      public_network_access_enabled = true
      site_config = {
        container_registry_use_managed_identity = true
        cors                                    = null
      }
      ip_restriction = {
        frontdoor = {
          name        = "AllowFrontDoor"
          priority    = 100
          action      = "Allow"
          ip_address  = null
          service_tag = "AzureFrontDoor.Backend"
        }
        myip = {
          name        = "AllowMyIP"
          priority    = 200
          action      = "Allow"
          ip_address  = "MyIP"
          service_tag = null
        }
      }
      scm_ip_restriction = {
        devops = {
          name        = "AllowDevOps"
          priority    = 100
          action      = "Allow"
          ip_address  = null
          service_tag = "AzureCloud"
        }
        myip = {
          name        = "AllowMyIP"
          priority    = 200
          action      = "Allow"
          ip_address  = "MyIP"
          service_tag = null
        }
      }
    }
  }
}

variable "function" {
  type = map(object({
    name                          = string
    target_service_plan           = string
    target_subnet                 = string
    target_key_vault_secret       = string
    target_user_assigned_identity = string
    target_application_insights   = string
    functions_extension_version   = string
    public_network_access_enabled = bool
    builtin_logging_enabled       = bool
    site_config = object({
      container_registry_use_managed_identity = bool
    })
    ip_restriction = map(object({
      name        = string
      priority    = number
      action      = string
      ip_address  = string
      service_tag = string
    }))
    scm_ip_restriction = map(object({
      name        = string
      priority    = number
      action      = string
      ip_address  = string
      service_tag = string
    }))
    app_service_logs = object({
      disk_quota_mb         = number
      retention_period_days = number
    })
  }))
  default = {
    func = {
      name                          = "func"
      target_service_plan           = "func"
      target_subnet                 = "func"
      target_key_vault_secret       = "FUNCTION_STORAGE_ACCOUNT_CONNECTION_STRING"
      target_user_assigned_identity = "func"
      target_application_insights   = "func"
      functions_extension_version   = "~4"
      public_network_access_enabled = true
      builtin_logging_enabled       = false
      site_config = {
        container_registry_use_managed_identity = true
      }
      ip_restriction = {
        myip = {
          name        = "AllowMyIP"
          priority    = 100
          action      = "Allow"
          ip_address  = "MyIP"
          service_tag = null
        }
      }
      scm_ip_restriction = {
        devops = {
          name        = "AllowDevOps"
          priority    = 100
          action      = "Allow"
          ip_address  = null
          service_tag = "AzureCloud"
        }
        myip = {
          name        = "AllowMyIP"
          priority    = 200
          action      = "Allow"
          ip_address  = "MyIP"
          service_tag = null
        }
      }
      app_service_logs = {
        disk_quota_mb         = 35
        retention_period_days = 7
      }
    }
  }
}

variable "openai" {
  type = map(object({
    name     = string
    location = string
    kind     = string
    sku_name = string
    network_acls = object({
      default_action = string
      ip_rules       = list(string)
    })
  }))
  default = {
    app = {
      name     = "app"
      location = "eastus2"
      kind     = "OpenAI"
      sku_name = "S0"
      network_acls = {
        default_action = "Deny"
        ip_rules       = ["MyIP"]
      }
    }
  }
}

variable "openai_deployment" {
  type = map(object({
    name                   = string
    target_openai          = string
    version_upgrade_option = string
    model = object({
      name    = string
      version = optional(string)
    })
    sku = object({
      name     = string
      capacity = number
    })
  }))
  default = {
    gpt_4_1 = {
      name                   = "gpt-4.1"
      target_openai          = "app"
      version_upgrade_option = "OnceNewDefaultVersionAvailable"
      model = {
        name    = "gpt-4.1"
        version = "2025-04-14"
      }
      sku = {
        name     = "GlobalStandard"
        capacity = 10
      }
    }
    o3_mini = {
      name                   = "o3-mini"
      target_openai          = "app"
      version_upgrade_option = "OnceNewDefaultVersionAvailable"
      model = {
        name    = "o3-mini"
        version = "2025-01-31"
      }
      sku = {
        name     = "GlobalStandard"
        capacity = 10
      }
    }
  }
}

variable "document_intelligence" {
  type = map(object({
    name     = string
    location = string
    kind     = string
    sku_name = string
    network_acls = object({
      default_action = string
      ip_rules       = list(string)
    })
  }))
  default = {
    app = {
      name     = "app"
      location = "eastus"
      kind     = "FormRecognizer"
      sku_name = "S0"
      network_acls = {
        default_action = "Deny"
        ip_rules       = ["MyIP"]
      }
    }
  }
}

variable "aisearch" {
  type = map(object({
    name                          = string
    sku                           = string
    semantic_search_sku           = string
    partition_count               = number
    replica_count                 = number
    public_network_access_enabled = bool
    network_rule_bypass_option    = string
    allowed_ips                   = list(string)
  }))
  default = {
    app = {
      name                          = "app"
      sku                           = "basic"
      semantic_search_sku           = "free"
      partition_count               = 1
      replica_count                 = 1
      public_network_access_enabled = true
      network_rule_bypass_option    = "AzureServices"
      allowed_ips                   = ["MyIP"]
    }
  }
}

variable "cosmosdb_account" {
  type = map(object({
    name                          = string
    offer_type                    = string
    kind                          = string
    free_tier_enabled             = bool
    public_network_access_enabled = bool
    ip_range_filter               = list(string)
    consistency_policy = object({
      consistency_level       = string
      max_interval_in_seconds = number
      max_staleness_prefix    = number
    })
    geo_location = object({
      location          = string
      failover_priority = number
      zone_redundant    = bool
    })
    capacity = object({
      total_throughput_limit = number
    })
    backup = object({
      type = string
      tier = string
    })
  }))
  default = {
    app = {
      name                          = "app"
      offer_type                    = "Standard"
      kind                          = "GlobalDocumentDB"
      free_tier_enabled             = false
      public_network_access_enabled = true
      ip_range_filter               = ["MyIP"]
      consistency_policy = {
        consistency_level       = "Session"
        max_interval_in_seconds = 5
        max_staleness_prefix    = 100
      }
      geo_location = {
        location          = "japaneast"
        failover_priority = 0
        zone_redundant    = false
      }
      capacity = {
        total_throughput_limit = 1000
      }
      backup = {
        type = "Continuous"
        tier = "Continuous7Days"
      }
    }
  }
}

variable "cosmosdb_sql_database" {
  type = map(object({
    name                    = string
    target_cosmosdb_account = string
    autoscale_settings = object({
      max_throughput = number
    })
  }))
  default = {
    database1 = {
      name                    = "database1"
      target_cosmosdb_account = "app"
      autoscale_settings = {
        max_throughput = 1000
      }
    }
  }
}

variable "cosmosdb_sql_container" {
  type = map(object({
    name                         = string
    target_cosmosdb_account      = string
    target_cosmosdb_sql_database = string
    partition_key_paths          = list(string)
    partition_key_version        = number
    autoscale_settings = object({
      max_throughput = number
    })
  }))
  default = {
    container1 = {
      name                         = "container1"
      target_cosmosdb_account      = "app"
      target_cosmosdb_sql_database = "database1"
      partition_key_paths          = ["/id"]
      partition_key_version        = 2
      autoscale_settings           = null
    }
  }
}

variable "mysql_flexible_server" {
  type = map(object({
    name                         = string
    target_vnet                  = string
    target_subnet                = string
    sku_name                     = string
    version                      = string
    backup_retention_days        = number
    geo_redundant_backup_enabled = bool
    zone                         = string
    high_availability = object({
      mode                      = string
      standby_availability_zone = string
    })
    storage = object({
      auto_grow_enabled = bool
      iops              = number
      size_gb           = number
    })
  }))
  default = {
    app = {
      name                         = "app"
      target_vnet                  = "spoke1"
      target_subnet                = "mysql"
      sku_name                     = "B_Standard_B1ms"
      version                      = "8.0.21"
      backup_retention_days        = 7
      geo_redundant_backup_enabled = false
      zone                         = "2"
      high_availability            = null
      storage = {
        auto_grow_enabled = true
        iops              = 360
        size_gb           = 20
      }
    }
  }
}

variable "mysql_authentication" {
  type = map(object({
    administrator_login               = string
    administrator_password_wo         = string
    administrator_password_wo_version = number
  }))
  default = {
    app = {
      administrator_login               = "your-username"
      administrator_password_wo         = "your-password"
      administrator_password_wo_version = 1
    }
  }
}

variable "mysql_flexible_database" {
  type = map(map(string))
  default = {
    database1 = {
      name                = "database1"
      target_mysql_server = "app"
      charset             = "utf8mb4"
      collation           = "utf8mb4_0900_ai_ci"
    }
  }
}

variable "postgresql_flexible_server" {
  type = map(object({
    name                          = string
    target_vnet                   = string
    target_subnet                 = string
    sku_name                      = string
    version                       = string
    backup_retention_days         = number
    geo_redundant_backup_enabled  = bool
    public_network_access_enabled = bool
    zone                          = string
    storage_mb                    = number
    storage_tier                  = optional(string)
    high_availability = optional(object({
      mode                      = string
      standby_availability_zone = string
    }))
  }))
  default = {
    app = {
      name                          = "app"
      target_vnet                   = "spoke1"
      target_subnet                 = "psql"
      sku_name                      = "B_Standard_B1ms"
      version                       = "17"
      backup_retention_days         = 7
      geo_redundant_backup_enabled  = false
      public_network_access_enabled = false
      zone                          = "2"
      storage_mb                    = 32768 # 32GB
      storage_tier                  = "P4"
      high_availability             = null
    }
  }
}

variable "postgresql_authentication" {
  type = map(object({
    administrator_login               = string
    administrator_password_wo         = string
    administrator_password_wo_version = number
  }))
  sensitive = true
  default = {
    app = {
      administrator_login               = "your-username"
      administrator_password_wo         = "your-password"
      administrator_password_wo_version = 1
    }
  }
}

variable "postgresql_flexible_database" {
  type = map(map(string))
  default = {
    database1 = {
      name                     = "appdb"
      target_postgresql_server = "app"
      charset                  = "UTF8"
      collation                = "ja_JP.utf8"
    }
  }
}

variable "mssql_database" {
  type = map(object({
    collation            = string
    max_size_gb          = number
    sku_name             = string # Basic, S0, S1... , GP_S_Gen5_2 etc.
    zone_redundant       = bool
    storage_account_type = string
    short_term_retention_policy = object({
      retention_days           = number # 1 - 35 days (Basic は最大 7 日)
      backup_interval_in_hours = number # 12 or 24 hours
    })
  }))
  default = {
    app = {
      collation            = "Japanese_CI_AS"
      max_size_gb          = 2
      sku_name             = "Basic"
      zone_redundant       = false
      storage_account_type = "Local"
      short_term_retention_policy = {
        retention_days           = 7
        backup_interval_in_hours = 12
      }
    }
  }
}

variable "firewall_rules" {
  type = map(object({
    start_ip_address = string
    end_ip_address   = string
  }))
  default = {
    single_ip = {
      start_ip_address = "40.112.8.12"
      end_ip_address   = "40.112.8.12"
    }
    ip_range = {
      start_ip_address = "40.112.0.0"
      end_ip_address   = "40.112.255.255"
    }
    # Azure サービスおよびリソースにこのサーバーへのアクセスを許可する
    # access_azure = {
    #   start_ip_address = "0.0.0.0"
    #   end_ip_address   = "0.0.0.0"
    # }
  }
}

variable "redis_cache" {
  type = map(object({
    name                          = string
    capacity                      = number
    family                        = string
    sku_name                      = string
    redis_version                 = number
    public_network_access_enabled = bool
    non_ssl_port_enabled          = bool
    minimum_tls_version           = string
  }))
  default = {
    app = {
      name                          = "app"
      capacity                      = 0
      family                        = "C"
      sku_name                      = "Basic"
      redis_version                 = 6
      public_network_access_enabled = false
      non_ssl_port_enabled          = false
      minimum_tls_version           = "1.2"
    }
  }
}

variable "vm" {
  type = map(object({
    os_type                         = string
    name                            = string
    target_subnet                   = string
    vm_size                         = string
    zone                            = string
    allow_extension_operations      = bool
    disable_password_authentication = optional(bool)
    encryption_at_host_enabled      = bool
    patch_mode                      = string
    secure_boot_enabled             = bool
    vtpm_enabled                    = bool
    os_disk = object({
      os_disk_cache             = string
      os_disk_type              = string
      os_disk_size              = number
      write_accelerator_enabled = bool
    })
    source_image_reference = object({
      offer     = string
      publisher = string
      sku       = string
      version   = string
    })
    public_ip = optional(object({
      sku               = string
      allocation_method = string
      zones             = list(string)
    }))
    vm_shutdown_schedule = object({
      daily_recurrence_time = string
      timezone              = string
      enabled               = bool
      notification_settings = object({
        enabled         = bool
        time_in_minutes = number
        email           = string
      })
    })
  }))
  default = {
    # jumpbox = {
    #   os_type                         = "Linux"
    #   name                            = "jumpbox"
    #   target_subnet                   = "vm"
    #   vm_size                         = "Standard_DS1_v2"
    #   zone                            = "1"
    #   allow_extension_operations      = true
    #   disable_password_authentication = true
    #   encryption_at_host_enabled      = false
    #   patch_mode                      = "ImageDefault"
    #   secure_boot_enabled             = true
    #   vtpm_enabled                    = true
    #   os_disk = {
    #     os_disk_cache             = "ReadWrite"
    #     os_disk_type              = "Standard_LRS"
    #     os_disk_size              = 30
    #     write_accelerator_enabled = false
    #   }
    #   source_image_reference = {
    #     offer     = "ubuntu-24_04-lts"
    #     publisher = "canonical"
    #     sku       = "server"
    #     version   = "latest"
    #   }
    #   public_ip = null
    #   vm_shutdown_schedule = {
    #     daily_recurrence_time = "1900"
    #     timezone              = "Tokyo Standard Time"
    #     enabled               = true
    #     notification_settings = {
    #       enabled         = false
    #       time_in_minutes = 15
    #       email           = "admin@example.com"
    #     }
    #   }
    # }
    dc = {
      os_type                    = "Windows"
      name                       = "dc"
      target_subnet              = "vm2"
      vm_size                    = "Standard_DS1_v2"
      zone                       = "1"
      allow_extension_operations = true
      encryption_at_host_enabled = false
      patch_mode                 = "AutomaticByOS"
      secure_boot_enabled        = true
      vtpm_enabled               = true
      os_disk = {
        os_disk_cache             = "ReadWrite"
        os_disk_type              = "Standard_LRS"
        os_disk_size              = 30
        write_accelerator_enabled = false
      }
      source_image_reference = {
        offer     = "WindowsServer"
        publisher = "MicrosoftWindowsServer"
        sku       = "2022-datacenter-azure-edition-smalldisk"
        version   = "latest"
      }
      public_ip = null
      vm_shutdown_schedule = {
        daily_recurrence_time = "1900"
        timezone              = "Tokyo Standard Time"
        enabled               = true
        notification_settings = {
          enabled         = false
          time_in_minutes = 15
          email           = "admin@example.com"
        }
      }
    }
  }
}

variable "vm_admin_username" {
  type    = string
  default = "azureuser"
}

variable "vm_admin_password" {
  type = string
}

variable "vmss" {
  type = map(object({
    name                        = string
    target_subnet               = string
    sku_name                    = string
    platform_fault_domain_count = number
    encryption_at_host_enabled  = bool
    instances                   = number
    zone_balance                = bool
    zones                       = list(string)
    os_profile = object({
      linux_configuration = object({
        patch_assessment_mode = string
        patch_mode            = string
        provision_vm_agent    = bool
      })
    })
    public_ip_address_enabled = bool
    os_disk = object({
      os_disk_cache             = string
      os_disk_type              = string
      os_disk_size              = number
      write_accelerator_enabled = bool
    })
    source_image_reference = object({
      offer     = string
      publisher = string
      sku       = string
      version   = string
    })
  }))
  default = {
    app = {
      name                        = "app"
      target_subnet               = "vm"
      sku_name                    = "Standard_DS1_v2"
      platform_fault_domain_count = 1
      encryption_at_host_enabled  = false
      instances                   = 2
      zone_balance                = true
      zones                       = ["1", "2", "3"]
      os_profile = {
        linux_configuration = {
          patch_assessment_mode = "ImageDefault"
          patch_mode            = "ImageDefault"
          provision_vm_agent    = true
        }
      }
      public_ip_address_enabled = true
      os_disk = {
        os_disk_cache             = "ReadWrite"
        os_disk_type              = "Standard_LRS"
        os_disk_size              = 30
        write_accelerator_enabled = false
      }
      source_image_reference = {
        offer     = "ubuntu-24_04-lts"
        publisher = "canonical"
        sku       = "server"
        version   = "latest"
      }
    }
  }
}

variable "vmss_admin_username" {
  type    = string
  default = "azureuser"
}

variable "loadbalancer" {
  type = object({
    sku               = string
    frontend_ip_name  = string
    backend_pool_name = string
    public_ip = object({
      sku               = string
      allocation_method = string
      zones             = list(string)
    })
    probe = object({
      name                = string
      port                = number
      interval_in_seconds = number
      number_of_probes    = number
      protocol            = string
      request_path        = string
    })
    rule = object({
      name                           = string
      protocol                       = string
      frontend_port                  = number
      backend_port                   = number
      frontend_ip_configuration_name = string
      enable_floating_ip             = bool
      idle_timeout_in_minutes        = number
      load_distribution              = string
      disable_outbound_snat          = bool
      enable_tcp_reset               = bool
    })
  })
  default = {
    sku               = "Standard"
    frontend_ip_name  = "frontend"
    backend_pool_name = "bepool"
    public_ip = {
      sku               = "Standard"
      allocation_method = "Static"
      zones             = ["1", "2", "3"]
    }
    probe = {
      name                = "http-probe"
      port                = 80
      interval_in_seconds = 5
      number_of_probes    = 3
      protocol            = "Http"
      request_path        = "/"
    }
    rule = {
      name                           = "http-rule"
      protocol                       = "Tcp"
      frontend_port                  = 80
      backend_port                   = 80
      frontend_ip_configuration_name = "frontend"
      enable_floating_ip             = false
      idle_timeout_in_minutes        = 4
      load_distribution              = "Default"
      disable_outbound_snat          = false
      enable_tcp_reset               = false
    }
  }
}

variable "application_gateway" {
  type = object({
    enable_http2                      = bool
    fips_enabled                      = bool
    force_firewall_policy_association = bool
    target_user_assigned_identity     = string
    zones                             = list(string)
    sku = object({
      name     = string
      tier     = string
      capacity = number
    })
    autoscale_configuration = object({
      min_capacity = number
      max_capacity = number
    })
    public_ip = object({
      sku               = string
      allocation_method = string
      zones             = list(string)
    })
  })
  default = {
    enable_http2                      = true
    fips_enabled                      = false
    force_firewall_policy_association = false
    target_user_assigned_identity     = "appgw"
    zones                             = ["1", "2", "3"]
    sku = {
      name     = "Standard_v2"
      tier     = "Standard_v2"
      capacity = 0
    }
    autoscale_configuration = {
      min_capacity = 1
      max_capacity = 2
    }
    public_ip = {
      sku               = "Standard"
      allocation_method = "Static"
      zones             = ["1", "2", "3"]
    }
  }
}

variable "automation_runbook" {
  type = map(object({
    schedule = optional(object({
      frequency   = string
      interval    = number
      timezone    = string
      start_time  = string
      description = string
      week_days   = optional(list(string))
    }))
  }))
  default = {
    Start-AksCluster = {
      schedule = {
        frequency   = "Week"
        interval    = 1
        timezone    = "Asia/Tokyo"
        start_time  = "08:00"
        description = "毎日 8:00 に AKS クラスターを開始"
        week_days   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
      }
    }
    Stop-AksCluster = {
      schedule = {
        frequency   = "Week"
        interval    = 1
        timezone    = "Asia/Tokyo"
        start_time  = "20:00"
        description = "毎日 20:00 に AKS クラスターを停止"
        week_days   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
      }
    }
    Start-ApplicationGateway = {
      schedule = {
        frequency   = "Week"
        interval    = 1
        timezone    = "Asia/Tokyo"
        start_time  = "08:00"
        description = "毎日 8:00 に Application Gateway を開始"
        week_days   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
      }
    }
    Stop-ApplicationGateway = {
      schedule = {
        frequency   = "Week"
        interval    = 1
        timezone    = "Asia/Tokyo"
        start_time  = "20:00"
        description = "毎日 20:00 に Application Gateway を停止"
        week_days   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
      }
    }
  }
}

variable "bastion" {
  type = object({
    target_subnet             = string
    sku                       = string
    scale_units               = number
    zones                     = list(string)
    copy_paste_enabled        = bool
    file_copy_enabled         = bool
    ip_connect_enabled        = bool
    kerberos_enabled          = bool
    shareable_link_enabled    = bool
    tunneling_enabled         = bool
    session_recording_enabled = bool
    public_ip = object({
      sku               = string
      allocation_method = string
      zones             = list(string)
    })
  })
  default = {
    target_subnet             = "bastion"
    sku                       = "Standard"
    scale_units               = 2
    zones                     = [] # Japan East is not supported at 2025/03
    copy_paste_enabled        = true
    file_copy_enabled         = true
    ip_connect_enabled        = true
    kerberos_enabled          = false
    shareable_link_enabled    = true
    tunneling_enabled         = true
    session_recording_enabled = false
    public_ip = {
      sku               = "Standard"
      allocation_method = "Static"
      zones             = ["1", "2", "3"]
    }
  }
}

variable "nat_gateway" {
  type = object({
    target_subnets          = list(string)
    sku_name                = string
    idle_timeout_in_minutes = number
    zones                   = list(string)
    public_ip = object({
      sku               = string
      allocation_method = string
      zones             = list(string)
    })
  })
  default = {
    target_subnets          = ["vm", "app", "func"]
    sku_name                = "Standard"
    idle_timeout_in_minutes = 4
    zones                   = ["1"]
    public_ip = {
      sku               = "Standard"
      allocation_method = "Static"
      zones             = ["1"]
    }
  }
}

variable "action_group" {
  type = map(object({
    name = string
    email_receivers = list(object({
      name                    = string
      email_address           = string
      use_common_alert_schema = bool
    }))
  }))
  default = {
    info = {
      name = "info"
      email_receivers = [
        {
          name                    = "運用チーム"
          email_address           = "support@example.com"
          use_common_alert_schema = true
        }
      ]
    }
  }
}

variable "service_health_alert" {
  type = map(object({
    name                = string
    target_action_group = string
    events              = list(string)
  }))
  default = {
    info = {
      name                = "Service Health Alert (Except Incidents)"
      target_action_group = "info"
      events              = ["Maintenance", "Informational", "ActionRequired", "Security"]
    }
    # incident = {
    #   name                = "Service Health Alert (Incidents Only)"
    #   target_action_group = "incident"
    #   events              = ["Incident"]
    # }
  }
}

variable "security_center_subscription_pricing" {
  type = map(object({
    tier          = string # 価格プラン: "Free" または "Standard"
    resource_type = string # リソースタイプ: "AI", "Api", "AppServices", "ContainerRegistry", "KeyVaults", "KubernetesService", "SqlServers", "SqlServerVirtualMachines", "StorageAccounts", "VirtualMachines", "Arm", "Dns", "OpenSourceRelationalDatabases", "Containers", "CosmosDbs", "CloudPosture" など。デフォルトは "VirtualMachines"
  }))
  default = {
    sql_databases = {
      tier          = "Standard"
      resource_type = "SqlServers"
    }
  }
}

variable "backup_policy_blob_storage" {
  type = object({
    operational_default_retention_duration = string
    vault_default_retention_duration       = string
    time_zone                              = string
    backup_repeating_time_intervals = object({
      time     = string
      interval = string
      timezone = string
    })
  })
  default = {
    operational_default_retention_duration = "P7D"
    vault_default_retention_duration       = "P7D"
    time_zone                              = "東京 (標準時)"
    backup_repeating_time_intervals = {
      time     = "01:00:00"
      interval = "P1D"
      timezone = "+09:00"
    }
  }
}

variable "security_contact" {
  type = object({
    emails     = list(string) # 通知を受け取る電子メールアドレスのリスト（セミコロン区切りの文字列に変換されます）
    is_enabled = bool         # 通知を有効にするかどうか
    notifications_by_role = object({
      state = string       # "On" または "Off"
      roles = list(string) # 通知を受け取るロール: "AccountAdmin", "Contributor", "Owner", "ServiceAdmin"
    })
    alert_notifications = object({
      minimal_severity = string # 通知する最小の重大度: "Low", "Medium", "High"（"Critical"は使用不可）
    })
    attack_path_notifications = object({
      enabled            = bool   # 攻撃パス通知を有効にするかどうか （攻撃パス分析には Defender CSPM 有料プランが必要）
      minimal_risk_level = string # 通知する最小のリスクレベル: "Low", "Medium", "High", "Critical"
    })
    phone = optional(string) # 電話番号（オプション）
  })
  default = {
    emails     = ["support@example.com", "info@example.com"]
    is_enabled = true
    notifications_by_role = {
      state = "On"
      roles = ["Owner"]
    }
    alert_notifications = {
      minimal_severity = "High"
    }
    attack_path_notifications = {
      enabled            = false
      minimal_risk_level = "Critical"
    }
    phone = null
  }
}

variable "role_definition" {
  type = map(object({
    name             = string
    description      = string
    actions          = list(string)
    not_actions      = list(string)
    data_actions     = list(string)
    not_data_actions = list(string)
  }))
  default = {
    restricted_contributor = {
      name        = "Contributor Without Log Analytics Access"
      description = "ContributorロールからLog Analyticsワークスペースのテーブル読み取りを除外したカスタムロール"
      actions     = ["*"]
      not_actions = [
        # Contributorロールの標準的な制限
        "Microsoft.Authorization/*/Delete",
        "Microsoft.Authorization/*/Write",
        "Microsoft.Authorization/elevateAccess/Action",
        "Microsoft.Blueprint/blueprintAssignments/write",
        "Microsoft.Blueprint/blueprintAssignments/delete",
        "Microsoft.Compute/galleries/share/action",
        "Microsoft.Purview/consents/write",
        "Microsoft.Purview/consents/delete",
        "Microsoft.Resources/deploymentStacks/manageDenySetting/action",
        "Microsoft.Subscription/cancel/action",
        "Microsoft.Subscription/enable/action",
        # Log Analyticsワークスペースのテーブルへの読み取りアクセスを禁止
        "Microsoft.OperationalInsights/workspaces/query/*/read",
        "Microsoft.Insights/logs/*/read",
      ]
      data_actions     = []
      not_data_actions = []
    }
  }
}
